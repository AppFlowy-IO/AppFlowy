use collab::core::origin::CollabOrigin;
use collab::preclude::Collab;
use collab_entity::CollabObject;
use collab_user::core::UserAwareness;
use lazy_static::lazy_static;
use std::sync::Arc;
use tokio::sync::Mutex;
use uuid::Uuid;

use flowy_error::FlowyError;
use flowy_user_pub::cloud::{UserCloudService, UserCollabParams};
use flowy_user_pub::entities::*;
use flowy_user_pub::DEFAULT_USER_NAME;
use lib_infra::async_trait::async_trait;
use lib_infra::box_any::BoxAny;
use lib_infra::util::timestamp;

use crate::local_server::uid::UserIDGenerator;
use crate::local_server::LocalServerDB;

lazy_static! {
  //FIXME: seriously, userID generation should work using lock-free algorithm
  static ref ID_GEN: Mutex<UserIDGenerator> = Mutex::new(UserIDGenerator::new(1));
}

pub(crate) struct LocalServerUserAuthServiceImpl {
  #[allow(dead_code)]
  pub db: Arc<dyn LocalServerDB>,
}

#[async_trait]
impl UserCloudService for LocalServerUserAuthServiceImpl {
  async fn sign_up(&self, params: BoxAny) -> Result<AuthResponse, FlowyError> {
    let params = params.unbox_or_error::<SignUpParams>()?;
    let uid = ID_GEN.lock().await.next_id();
    let workspace_id = uuid::Uuid::new_v4().to_string();
    let user_workspace = UserWorkspace::new(&workspace_id, uid);
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
      email: Some(params.email),
      token: None,
      encryption_type: EncryptionType::NoEncryption,
      updated_at: timestamp(),
      metadata: None,
    })
  }

  async fn sign_in(&self, params: BoxAny) -> Result<AuthResponse, FlowyError> {
    let db = self.db.clone();
    let params: SignInParams = params.unbox_or_error::<SignInParams>()?;
    let uid = ID_GEN.lock().await.next_id();

    let user_workspace = db
      .get_user_workspace(uid)?
      .unwrap_or_else(make_user_workspace);
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
  ) -> Result<UserProfile, FlowyError> {
    Err(FlowyError::local_version_not_support().with_context("Not support"))
  }

  async fn sign_in_with_magic_link(
    &self,
    _email: &str,
    _redirect_to: &str,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support().with_context("Not support"))
  }

  async fn generate_oauth_url_with_provider(&self, _provider: &str) -> Result<String, FlowyError> {
    Err(FlowyError::internal().with_context("Can't oauth url when using offline mode"))
  }

  async fn update_user(
    &self,
    _credential: UserCredentials,
    _params: UpdateUserProfileParams,
  ) -> Result<(), FlowyError> {
    Ok(())
  }

  async fn get_user_profile(&self, credential: UserCredentials) -> Result<UserProfile, FlowyError> {
    match credential.uid {
      None => Err(FlowyError::record_not_found()),
      Some(uid) => {
        self.db.get_user_profile(uid).map(|mut profile| {
          // We don't want to expose the email in the local server
          profile.email = "".to_string();
          profile
        })
      },
    }
  }

  async fn open_workspace(&self, _workspace_id: &str) -> Result<UserWorkspace, FlowyError> {
    Err(
      FlowyError::local_version_not_support()
        .with_context("local server doesn't support open workspace"),
    )
  }

  async fn get_all_workspace(&self, _uid: i64) -> Result<Vec<UserWorkspace>, FlowyError> {
    Ok(vec![])
  }

  async fn get_user_awareness_doc_state(
    &self,
    _uid: i64,
    _workspace_id: &str,
    object_id: &str,
  ) -> Result<Vec<u8>, FlowyError> {
    let collab = Collab::new_with_origin(CollabOrigin::Empty, object_id, vec![], false);
    let awareness = UserAwareness::create(collab, None)?;
    let encode_collab = awareness.encode_collab_v1(|_collab| Ok::<_, FlowyError>(()))?;
    Ok(encode_collab.doc_state.to_vec())
  }

  async fn reset_workspace(&self, _collab_object: CollabObject) -> Result<(), FlowyError> {
    Ok(())
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
    _workspace_id: &str,
    _objects: Vec<UserCollabParams>,
  ) -> Result<(), FlowyError> {
    Err(
      FlowyError::local_version_not_support()
        .with_context("local server doesn't support batch create collab object"),
    )
  }

  async fn create_workspace(&self, _workspace_name: &str) -> Result<UserWorkspace, FlowyError> {
    Err(
      FlowyError::local_version_not_support()
        .with_context("local server doesn't support multiple workspaces"),
    )
  }

  async fn delete_workspace(&self, _workspace_id: &str) -> Result<(), FlowyError> {
    Err(
      FlowyError::local_version_not_support()
        .with_context("local server doesn't support multiple workspaces"),
    )
  }

  async fn patch_workspace(
    &self,
    _workspace_id: &str,
    _new_workspace_name: Option<&str>,
    _new_workspace_icon: Option<&str>,
  ) -> Result<(), FlowyError> {
    Err(
      FlowyError::local_version_not_support()
        .with_context("local server doesn't support multiple workspaces"),
    )
  }
}

fn make_user_workspace() -> UserWorkspace {
  UserWorkspace {
    id: uuid::Uuid::new_v4().to_string(),
    name: "My Workspace".to_string(),
    created_at: Default::default(),
    workspace_database_id: uuid::Uuid::new_v4().to_string(),
    icon: "".to_string(),
    member_count: 0,
  }
}
