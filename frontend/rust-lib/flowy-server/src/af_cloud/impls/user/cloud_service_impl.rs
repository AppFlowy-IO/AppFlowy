use std::collections::HashMap;
use std::sync::Arc;

use anyhow::anyhow;
use client_api::entity::workspace_dto::{
  CreateWorkspaceMember, CreateWorkspaceParam, PatchWorkspaceParam, WorkspaceMemberChangeset,
};
use client_api::entity::{
  AFRole, AFWorkspace, AuthProvider, CollabParams, CreateCollabParams, QueryCollab,
  QueryCollabParams,
};
use client_api::{Client, ClientConfiguration};
use collab_entity::{CollabObject, CollabType};
use parking_lot::RwLock;

use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_user_pub::cloud::{UserCloudService, UserCollabParams, UserUpdate, UserUpdateReceiver};
use flowy_user_pub::entities::*;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;
use uuid::Uuid;

use crate::af_cloud::define::USER_SIGN_IN_URL;
use crate::af_cloud::impls::user::dto::{
  af_update_from_update_params, from_af_workspace_member, to_af_role, user_profile_from_af_profile,
};
use crate::af_cloud::impls::user::util::encryption_type_from_profile;
use crate::af_cloud::{AFCloudClient, AFServer};

pub(crate) struct AFCloudUserAuthServiceImpl<T> {
  server: T,
  user_change_recv: RwLock<Option<tokio::sync::mpsc::Receiver<UserUpdate>>>,
}

impl<T> AFCloudUserAuthServiceImpl<T> {
  pub(crate) fn new(server: T, user_change_recv: tokio::sync::mpsc::Receiver<UserUpdate>) -> Self {
    Self {
      server,
      user_change_recv: RwLock::new(Some(user_change_recv)),
    }
  }
}

impl<T> UserCloudService for AFCloudUserAuthServiceImpl<T>
where
  T: AFServer,
{
  fn sign_up(&self, params: BoxAny) -> FutureResult<AuthResponse, FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let params = oauth_params_from_box_any(params)?;
      let resp = user_sign_up_request(try_get_client?, params).await?;
      Ok(resp)
    })
  }

  // Zack: Not sure if this is needed anymore since sign_up handles both cases
  fn sign_in(&self, params: BoxAny) -> FutureResult<AuthResponse, FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let params = oauth_params_from_box_any(params)?;
      let resp = user_sign_in_with_url(client, params).await?;
      Ok(resp)
    })
  }

  fn sign_out(&self, _token: Option<String>) -> FutureResult<(), FlowyError> {
    // Calling the sign_out method that will revoke all connected devices' refresh tokens.
    // So do nothing here.
    FutureResult::new(async move { Ok(()) })
  }

  fn generate_sign_in_url_with_email(&self, email: &str) -> FutureResult<String, FlowyError> {
    let email = email.to_string();
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let admin_client = get_admin_client(&client).await?;
      let action_link = admin_client.generate_sign_in_action_link(&email).await?;
      let sign_in_url = client.extract_sign_in_url(&action_link).await?;
      Ok(sign_in_url)
    })
  }

  fn create_user(&self, email: &str, password: &str) -> FutureResult<(), FlowyError> {
    let password = password.to_string();
    let email = email.to_string();
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let admin_client = get_admin_client(&client).await?;
      admin_client
        .create_email_verified_user(&email, &password)
        .await?;

      Ok(())
    })
  }

  fn sign_in_with_password(
    &self,
    email: &str,
    password: &str,
  ) -> FutureResult<UserProfile, FlowyError> {
    let password = password.to_string();
    let email = email.to_string();
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      client.sign_in_password(&email, &password).await?;
      let profile = client.get_profile().await?;
      let token = client.get_token()?;
      let profile = user_profile_from_af_profile(token, profile)?;
      Ok(profile)
    })
  }

  fn generate_oauth_url_with_provider(&self, provider: &str) -> FutureResult<String, FlowyError> {
    let provider = AuthProvider::from(provider);
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let provider = provider.ok_or(anyhow!("invalid provider"))?;
      let url = try_get_client?
        .generate_oauth_url_with_provider(&provider)
        .await?;
      Ok(url)
    })
  }

  fn update_user(
    &self,
    _credential: UserCredentials,
    params: UpdateUserProfileParams,
  ) -> FutureResult<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      client
        .update_user(af_update_from_update_params(params))
        .await?;
      Ok(())
    })
  }

  fn get_user_profile(
    &self,
    _credential: UserCredentials,
  ) -> FutureResult<UserProfile, FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let profile = client.get_profile().await?;
      let token = client.get_token()?;
      let profile = user_profile_from_af_profile(token, profile)?;
      Ok(profile)
    })
  }

  fn open_workspace(&self, workspace_id: &str) -> FutureResult<UserWorkspace, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let workspace_id = workspace_id.to_string();
    FutureResult::new(async move {
      let client = try_get_client?;
      let af_workspace = client.open_workspace(&workspace_id).await?;
      Ok(to_user_workspace(af_workspace))
    })
  }

  fn get_all_workspace(&self, _uid: i64) -> FutureResult<Vec<UserWorkspace>, FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let workspaces = try_get_client?.get_workspaces().await?;
      to_user_workspaces(workspaces.0)
    })
  }

  #[allow(deprecated)]
  fn add_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
  ) -> FutureResult<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      // TODO(zack): add_workspace_members will be deprecated after finishing the invite logic. Don't forget to remove the #[allow(deprecated)]
      try_get_client?
        .add_workspace_members(
          workspace_id,
          vec![CreateWorkspaceMember {
            email: user_email,
            role: AFRole::Member,
          }],
        )
        .await?;
      Ok(())
    })
  }

  fn remove_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
  ) -> FutureResult<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      try_get_client?
        .remove_workspace_members(workspace_id, vec![user_email])
        .await?;
      Ok(())
    })
  }

  fn update_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
    role: Role,
  ) -> FutureResult<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let changeset = WorkspaceMemberChangeset::new(user_email).with_role(to_af_role(role));
      try_get_client?
        .update_workspace_member(workspace_id, changeset)
        .await?;
      Ok(())
    })
  }

  fn get_workspace_members(
    &self,
    workspace_id: String,
  ) -> FutureResult<Vec<WorkspaceMember>, FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let members = try_get_client?
        .get_workspace_members(&workspace_id)
        .await?
        .into_iter()
        .map(from_af_workspace_member)
        .collect();
      Ok(members)
    })
  }

  fn get_user_awareness_doc_state(
    &self,
    _uid: i64,
    workspace_id: &str,
    object_id: &str,
  ) -> FutureResult<Vec<u8>, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let object_id = object_id.to_string();
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async {
      let params = QueryCollabParams {
        workspace_id,
        inner: QueryCollab {
          object_id,
          collab_type: CollabType::UserAwareness,
        },
      };

      let resp = try_get_client?.get_collab(params).await?;
      Ok(resp.doc_state.to_vec())
    })
  }

  fn subscribe_user_update(&self) -> Option<UserUpdateReceiver> {
    self.user_change_recv.write().take()
  }

  fn reset_workspace(&self, _collab_object: CollabObject) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn create_collab_object(
    &self,
    collab_object: &CollabObject,
    data: Vec<u8>,
  ) -> FutureResult<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    let collab_object = collab_object.clone();
    FutureResult::new(async move {
      let client = try_get_client?;
      let params = CreateCollabParams {
        workspace_id: collab_object.workspace_id.clone(),
        object_id: collab_object.object_id.clone(),
        encoded_collab_v1: data,
        collab_type: collab_object.collab_type.clone(),
      };
      client.create_collab(params).await?;
      Ok(())
    })
  }

  fn batch_create_collab_object(
    &self,
    workspace_id: &str,
    objects: Vec<UserCollabParams>,
  ) -> FutureResult<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let params = objects
        .into_iter()
        .map(|object| CollabParams {
          object_id: object.object_id,
          encoded_collab_v1: object.encoded_collab,
          collab_type: object.collab_type,
        })
        .collect::<Vec<_>>();
      try_get_client?
        .create_collab_list(&workspace_id, params)
        .await
        .map_err(FlowyError::from)?;
      Ok(())
    })
  }

  fn create_workspace(&self, workspace_name: &str) -> FutureResult<UserWorkspace, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let workspace_name_owned = workspace_name.to_owned();
    FutureResult::new(async move {
      let client = try_get_client?;
      let new_workspace = client
        .create_workspace(CreateWorkspaceParam {
          workspace_name: Some(workspace_name_owned),
        })
        .await?;
      Ok(to_user_workspace(new_workspace))
    })
  }

  fn delete_workspace(&self, workspace_id: &str) -> FutureResult<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    let workspace_id_owned = workspace_id.to_owned();
    FutureResult::new(async move {
      let client = try_get_client?;
      client.delete_workspace(&workspace_id_owned).await?;
      Ok(())
    })
  }

  fn patch_workspace(
    &self,
    workspace_id: &str,
    new_workspace_name: Option<&str>,
    new_workspace_icon: Option<&str>,
  ) -> FutureResult<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    let owned_workspace_id = workspace_id.to_owned();
    let owned_workspace_name = new_workspace_name.map(|s| s.to_owned());
    let owned_workspace_icon = new_workspace_icon.map(|s| s.to_owned());
    FutureResult::new(async move {
      let workspace_id: Uuid = owned_workspace_id
        .parse()
        .map_err(|_| ErrorCode::InvalidParams)?;
      let client = try_get_client?;
      client
        .patch_workspace(PatchWorkspaceParam {
          workspace_id,
          workspace_name: owned_workspace_name,
          workspace_icon: owned_workspace_icon,
        })
        .await?;
      Ok(())
    })
  }

  fn leave_workspace(&self, workspace_id: &str) -> FutureResult<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    let workspace_id = workspace_id.to_string();
    FutureResult::new(async move {
      let client = try_get_client?;
      client.leave_workspace(&workspace_id).await?;
      Ok(())
    })
  }
}

async fn get_admin_client(client: &Arc<AFCloudClient>) -> FlowyResult<Client> {
  let admin_email =
    std::env::var("GOTRUE_ADMIN_EMAIL").unwrap_or_else(|_| "admin@example.com".to_string());
  let admin_password =
    std::env::var("GOTRUE_ADMIN_PASSWORD").unwrap_or_else(|_| "password".to_string());
  let admin_client = client_api::Client::new(
    client.base_url(),
    client.ws_addr(),
    client.gotrue_url(),
    &client.device_id,
    ClientConfiguration::default(),
    &client.client_version.to_string(),
  );
  admin_client
    .sign_in_password(&admin_email, &admin_password)
    .await?;
  Ok(admin_client)
}

pub async fn user_sign_up_request(
  client: Arc<AFCloudClient>,
  params: AFCloudOAuthParams,
) -> Result<AuthResponse, FlowyError> {
  user_sign_in_with_url(client, params).await
}

pub async fn user_sign_in_with_url(
  client: Arc<AFCloudClient>,
  params: AFCloudOAuthParams,
) -> Result<AuthResponse, FlowyError> {
  let is_new_user = client.sign_in_with_url(&params.sign_in_url).await?;

  let workspace_profile = client.get_user_workspace_info().await?;
  let user_profile = workspace_profile.user_profile;

  let latest_workspace = to_user_workspace(workspace_profile.visiting_workspace);
  let user_workspaces = to_user_workspaces(workspace_profile.workspaces)?;
  let encryption_type = encryption_type_from_profile(&user_profile);

  Ok(AuthResponse {
    user_id: user_profile.uid,
    user_uuid: user_profile.uuid,
    name: user_profile.name.unwrap_or_default(),
    latest_workspace,
    user_workspaces,
    email: user_profile.email,
    token: Some(client.get_token()?),
    encryption_type,
    is_new_user,
    updated_at: user_profile.updated_at,
    metadata: user_profile.metadata,
  })
}

fn to_user_workspace(af_workspace: AFWorkspace) -> UserWorkspace {
  UserWorkspace {
    id: af_workspace.workspace_id.to_string(),
    name: af_workspace.workspace_name,
    created_at: af_workspace.created_at,
    workspace_database_object_id: af_workspace.database_storage_id.to_string(),
    icon: af_workspace.icon,
  }
}

fn to_user_workspaces(workspaces: Vec<AFWorkspace>) -> Result<Vec<UserWorkspace>, FlowyError> {
  let mut result = Vec::with_capacity(workspaces.len());
  for item in workspaces.into_iter() {
    result.push(to_user_workspace(item));
  }
  Ok(result)
}

fn oauth_params_from_box_any(any: BoxAny) -> Result<AFCloudOAuthParams, FlowyError> {
  let map: HashMap<String, String> = any.unbox_or_error()?;
  let sign_in_url = map
    .get(USER_SIGN_IN_URL)
    .ok_or_else(|| FlowyError::new(ErrorCode::MissingAuthField, "Missing token field"))?
    .as_str();
  Ok(AFCloudOAuthParams {
    sign_in_url: sign_in_url.to_string(),
  })
}
