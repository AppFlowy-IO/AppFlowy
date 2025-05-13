#![allow(unused_variables)]

use crate::af_cloud::define::LoggedUser;
use crate::local_server::template::create_workspace::{
  CreateWorkspaceCollab, create_workspace_for_user,
};
use crate::local_server::uid::IDGenerator;
use anyhow::Context;
use client_api::entity::GotrueTokenResponse;
use collab::core::origin::CollabOrigin;
use collab::preclude::Collab;
use collab_entity::CollabObject;
use collab_plugins::CollabKVDB;
use collab_plugins::local_storage::kv::KVTransactionDB;
use collab_plugins::local_storage::kv::doc::CollabKVAction;
use collab_user::core::UserAwareness;
use flowy_ai_pub::cloud::billing_dto::WorkspaceUsageAndLimit;
use flowy_ai_pub::cloud::{AFWorkspaceSettings, AFWorkspaceSettingsChange};
use flowy_error::{FlowyError, FlowyResult};
use flowy_user_pub::DEFAULT_USER_NAME;
use flowy_user_pub::cloud::{UserCloudService, UserCollabParams};
use flowy_user_pub::entities::*;
use flowy_user_pub::sql::{
  UserTableChangeset, WorkspaceMemberTable, WorkspaceSettingsChangeset, WorkspaceSettingsTable,
  insert_local_workspace, select_all_user_workspace, select_user_profile, select_user_workspace,
  select_workspace_member, select_workspace_setting, update_user_profile, update_workspace_setting,
  upsert_workspace_member, upsert_workspace_setting,
};
use lazy_static::lazy_static;
use lib_infra::async_trait::async_trait;
use lib_infra::box_any::BoxAny;
use lib_infra::util::timestamp;
use std::sync::Arc;
use tokio::sync::Mutex;
use uuid::Uuid;

lazy_static! {
  static ref ID_GEN: Mutex<IDGenerator> = Mutex::new(IDGenerator::new(1));
}

pub(crate) struct LocalServerUserServiceImpl {
  pub logged_user: Arc<dyn LoggedUser>,
}

#[async_trait]
impl UserCloudService for LocalServerUserServiceImpl {
  async fn sign_up(&self, params: BoxAny) -> Result<AuthResponse, FlowyError> {
    let params = params.unbox_or_error::<SignUpParams>()?;
    let uid = ID_GEN.lock().await.next_id();
    let workspace_id = Uuid::new_v4().to_string();
    let user_workspace = UserWorkspace::new_local(workspace_id, "My Workspace");
    let user_name = if params.name.is_empty() {
      DEFAULT_USER_NAME()
    } else {
      params.name.clone()
    };
    Ok(AuthResponse {
      user_id: uid,
      user_uuid: Uuid::new_v4(),
      name: user_name,
      latest_workspace: user_workspace.clone(),
      user_workspaces: vec![user_workspace],
      is_new_user: true,
      // Anon user doesn't have email
      email: None,
      token: None,
      encryption_type: EncryptionType::NoEncryption,
      updated_at: timestamp(),
      metadata: None,
    })
  }

  async fn sign_in(&self, params: BoxAny) -> Result<AuthResponse, FlowyError> {
    let params: SignInParams = params.unbox_or_error::<SignInParams>()?;
    let uid = ID_GEN.lock().await.next_id();

    let workspace_id = Uuid::new_v4();
    let user_workspace = UserWorkspace::new_local(workspace_id.to_string(), "My Workspace");
    Ok(AuthResponse {
      user_id: uid,
      user_uuid: Uuid::new_v4(),
      name: params.name,
      latest_workspace: user_workspace.clone(),
      user_workspaces: vec![user_workspace],
      is_new_user: false,
      email: Some(params.email),
      token: None,
      encryption_type: EncryptionType::NoEncryption,
      updated_at: timestamp(),
      metadata: None,
    })
  }

  async fn sign_out(&self, _token: Option<String>) -> Result<(), FlowyError> {
    Ok(())
  }

  async fn generate_sign_in_url_with_email(&self, _email: &str) -> Result<String, FlowyError> {
    Err(
      FlowyError::local_version_not_support()
        .with_context("Not support generate sign in url with email"),
    )
  }

  async fn create_user(&self, _email: &str, _password: &str) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support().with_context("Not support create user"))
  }

  async fn sign_in_with_password(
    &self,
    _email: &str,
    _password: &str,
  ) -> Result<GotrueTokenResponse, FlowyError> {
    Err(FlowyError::local_version_not_support().with_context("Not support"))
  }

  async fn sign_in_with_magic_link(
    &self,
    _email: &str,
    _redirect_to: &str,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support().with_context("Not support"))
  }

  async fn sign_in_with_passcode(
    &self,
    _email: &str,
    _passcode: &str,
  ) -> Result<GotrueTokenResponse, FlowyError> {
    Err(FlowyError::local_version_not_support().with_context("Not support"))
  }

  async fn generate_oauth_url_with_provider(&self, _provider: &str) -> Result<String, FlowyError> {
    Err(FlowyError::internal().with_context("Can't oauth url when using offline mode"))
  }

  async fn update_user(&self, params: UpdateUserProfileParams) -> Result<(), FlowyError> {
    let uid = self.logged_user.user_id()?;
    let mut conn = self.logged_user.get_sqlite_db(uid)?;
    let changeset = UserTableChangeset::new(params);
    update_user_profile(&mut conn, changeset)?;
    Ok(())
  }

  async fn get_user_profile(
    &self,
    uid: i64,
    workspace_id: &str,
  ) -> Result<UserProfile, FlowyError> {
    let mut conn = self.logged_user.get_sqlite_db(uid)?;
    let profile = select_user_profile(uid, workspace_id, &mut conn)?;
    Ok(profile)
  }

  async fn open_workspace(&self, workspace_id: &Uuid) -> Result<UserWorkspace, FlowyError> {
    let uid = self.logged_user.user_id()?;
    let mut conn = self.logged_user.get_sqlite_db(uid)?;

    let workspace = select_user_workspace(&workspace_id.to_string(), &mut conn)?;
    Ok(UserWorkspace::from(workspace))
  }

  async fn get_all_workspace(&self, uid: i64) -> Result<Vec<UserWorkspace>, FlowyError> {
    let mut conn = self.logged_user.get_sqlite_db(uid)?;
    let workspaces = select_all_user_workspace(uid, &mut conn)?;
    Ok(workspaces)
  }

  async fn create_workspace(&self, workspace_name: &str) -> Result<UserWorkspace, FlowyError> {
    let workspace_id = Uuid::new_v4();
    let uid = self.logged_user.user_id()?;

    let collab_db = self
      .logged_user
      .get_collab_db(uid)?
      .upgrade()
      .ok_or_else(FlowyError::ref_drop)?;
    let collab_params = create_workspace_for_user(uid, &workspace_id).await?;
    insert_collabs(collab_db, uid, &workspace_id.to_string(), collab_params)?;
    // insert collab

    let mut conn = self.logged_user.get_sqlite_db(uid)?;
    let user_workspace =
      insert_local_workspace(uid, &workspace_id.to_string(), workspace_name, &mut conn)?;
    Ok(user_workspace)
  }

  async fn patch_workspace(
    &self,
    workspace_id: &Uuid,
    new_workspace_name: Option<String>,
    new_workspace_icon: Option<String>,
  ) -> Result<(), FlowyError> {
    Ok(())
  }

  async fn delete_workspace(&self, workspace_id: &Uuid) -> Result<(), FlowyError> {
    Ok(())
  }

  async fn get_workspace_members(
    &self,
    workspace_id: Uuid,
  ) -> Result<Vec<WorkspaceMember>, FlowyError> {
    let uid = self.logged_user.user_id()?;
    let member = self.get_workspace_member(&workspace_id, uid).await?;
    Ok(vec![member])
  }

  async fn get_user_awareness_doc_state(
    &self,
    uid: i64,
    workspace_id: &Uuid,
    object_id: &Uuid,
  ) -> Result<Vec<u8>, FlowyError> {
    let collab = Collab::new_with_origin(
      CollabOrigin::Empty,
      object_id.to_string().as_str(),
      vec![],
      false,
    );
    let awareness = UserAwareness::create(collab, None)?;
    let encode_collab = awareness.encode_collab_v1(|_collab| Ok::<_, FlowyError>(()))?;
    Ok(encode_collab.doc_state.to_vec())
  }

  async fn create_collab_object(
    &self,
    _collab_object: &CollabObject,
    _data: Vec<u8>,
  ) -> Result<(), FlowyError> {
    Ok(())
  }

  async fn batch_create_collab_object(
    &self,
    workspace_id: &Uuid,
    objects: Vec<UserCollabParams>,
  ) -> Result<(), FlowyError> {
    Ok(())
  }

  async fn get_workspace_member(
    &self,
    workspace_id: &Uuid,
    uid: i64,
  ) -> Result<WorkspaceMember, FlowyError> {
    // For local server, only current user is the member
    let conn = self.logged_user.get_sqlite_db(uid)?;
    let result = select_workspace_member(conn, &workspace_id.to_string(), uid);

    match result {
      Ok(row) => Ok(WorkspaceMember::from(row)),
      Err(err) => {
        if err.is_record_not_found() {
          let mut conn = self.logged_user.get_sqlite_db(uid)?;
          let profile = select_user_profile(uid, &workspace_id.to_string(), &mut conn)
            .context("Can't find user profile when create workspace member")?;
          let row = WorkspaceMemberTable {
            email: profile.email.to_string(),
            role: Role::Owner as i32,
            name: profile.name.to_string(),
            avatar_url: Some(profile.icon_url),
            uid,
            workspace_id: workspace_id.to_string(),
            updated_at: chrono::Utc::now().naive_utc(),
            joined_at: None,
          };

          let member = WorkspaceMember::from(row.clone());
          upsert_workspace_member(&mut conn, row)?;
          Ok(member)
        } else {
          Err(err)
        }
      },
    }
  }

  async fn get_workspace_usage(
    &self,
    workspace_id: &Uuid,
  ) -> Result<WorkspaceUsageAndLimit, FlowyError> {
    Ok(WorkspaceUsageAndLimit {
      member_count: 1,
      member_count_limit: 1,
      storage_bytes: i64::MAX,
      storage_bytes_limit: i64::MAX,
      storage_bytes_unlimited: true,
      single_upload_limit: i64::MAX,
      single_upload_unlimited: true,
      ai_responses_count: i64::MAX,
      ai_responses_count_limit: i64::MAX,
      ai_image_responses_count: i64::MAX,
      ai_image_responses_count_limit: 0,
      local_ai: true,
      ai_responses_unlimited: true,
    })
  }

  async fn get_workspace_setting(
    &self,
    workspace_id: &Uuid,
  ) -> Result<AFWorkspaceSettings, FlowyError> {
    let uid = self.logged_user.user_id()?;
    let mut conn = self.logged_user.get_sqlite_db(uid)?;

    // By default, workspace setting is existed in local server
    let result = select_workspace_setting(&mut conn, &workspace_id.to_string());
    match result {
      Ok(row) => Ok(AFWorkspaceSettings {
        disable_search_indexing: row.disable_search_indexing,
        ai_model: row.ai_model,
      }),
      Err(err) => {
        if err.is_record_not_found() {
          let row = WorkspaceSettingsTable {
            id: workspace_id.to_string(),
            disable_search_indexing: false,
            ai_model: "".to_string(),
          };
          let setting = AFWorkspaceSettings {
            disable_search_indexing: row.disable_search_indexing,
            ai_model: row.ai_model.clone(),
          };
          upsert_workspace_setting(&mut conn, row)?;
          Ok(setting)
        } else {
          Err(err)
        }
      },
    }
  }

  async fn update_workspace_setting(
    &self,
    workspace_id: &Uuid,
    workspace_settings: AFWorkspaceSettingsChange,
  ) -> Result<AFWorkspaceSettings, FlowyError> {
    let uid = self.logged_user.user_id()?;
    let mut conn = self.logged_user.get_sqlite_db(uid)?;

    let changeset = WorkspaceSettingsChangeset {
      id: workspace_id.to_string(),
      disable_search_indexing: workspace_settings.disable_search_indexing,
      ai_model: workspace_settings.ai_model,
    };

    update_workspace_setting(&mut conn, changeset)?;
    let row = select_workspace_setting(&mut conn, &workspace_id.to_string())?;

    Ok(AFWorkspaceSettings {
      disable_search_indexing: row.disable_search_indexing,
      ai_model: row.ai_model,
    })
  }
}

fn insert_collabs(
  db: Arc<CollabKVDB>,
  uid: i64,
  workspace_id: &str,
  params_list: Vec<CreateWorkspaceCollab>,
) -> FlowyResult<()> {
  let write = db.write_txn();
  for params in params_list {
    write.flush_doc(
      uid,
      workspace_id,
      &params.object_id.to_string(),
      params.encoded_collab.state_vector.to_vec(),
      params.encoded_collab.doc_state.to_vec(),
    )?
  }

  write.commit_transaction()?;
  Ok(())
}
