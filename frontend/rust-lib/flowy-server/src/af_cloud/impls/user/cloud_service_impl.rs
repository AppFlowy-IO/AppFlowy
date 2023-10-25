use std::collections::HashMap;
use std::sync::Arc;

use anyhow::{anyhow, Error};
use client_api::entity::workspace_dto::{CreateWorkspaceMember, WorkspaceMemberChangeset};
use client_api::entity::{AFRole, AFWorkspace, InsertCollabParams, OAuthProvider};
use collab_entity::CollabObject;

use flowy_error::{ErrorCode, FlowyError};
use flowy_user_deps::cloud::UserCloudService;
use flowy_user_deps::entities::*;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::af_cloud::impls::user::dto::{
  af_update_from_update_params, from_af_workspace_member, to_af_role, user_profile_from_af_profile,
};
use crate::af_cloud::impls::user::util::encryption_type_from_profile;
use crate::af_cloud::{AFCloudClient, AFServer};
use crate::supabase::define::{USER_DEVICE_ID, USER_SIGN_IN_URL};

pub(crate) struct AFCloudUserAuthServiceImpl<T> {
  server: T,
}

impl<T> AFCloudUserAuthServiceImpl<T> {
  pub(crate) fn new(server: T) -> Self {
    Self { server }
  }
}

impl<T> UserCloudService for AFCloudUserAuthServiceImpl<T>
where
  T: AFServer,
{
  fn sign_up(&self, params: BoxAny) -> FutureResult<AuthResponse, Error> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let params = oauth_params_from_box_any(params)?;
      let resp = user_sign_up_request(try_get_client?, params).await?;
      Ok(resp)
    })
  }

  // Zack: Not sure if this is needed anymore since sign_up handles both cases
  fn sign_in(&self, params: BoxAny) -> FutureResult<AuthResponse, Error> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let params = oauth_params_from_box_any(params)?;
      let resp = user_sign_in_with_url(client, params).await?;
      Ok(resp)
    })
  }

  fn sign_out(&self, _token: Option<String>) -> FutureResult<(), Error> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move { Ok(try_get_client?.sign_out().await?) })
  }

  fn generate_sign_in_url_with_email(&self, email: &str) -> FutureResult<String, Error> {
    let email = email.to_string();
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      // TODO(nathan): replace the admin_email and admin_password with encryption key
      let admin_email = std::env::var("GOTRUE_ADMIN_EMAIL").unwrap();
      let admin_password = std::env::var("GOTRUE_ADMIN_PASSWORD").unwrap();
      let url = try_get_client?
        .generate_sign_in_url_with_email(&admin_email, &admin_password, &email)
        .await?;
      Ok(url)
    })
  }

  fn generate_oauth_url_with_provider(&self, provider: &str) -> FutureResult<String, Error> {
    let provider = OAuthProvider::from(provider);
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
  ) -> FutureResult<(), Error> {
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

  fn get_all_user_workspaces(&self, _uid: i64) -> FutureResult<Vec<UserWorkspace>, Error> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let workspaces = try_get_client?.get_workspaces().await?;
      Ok(to_user_workspaces(workspaces.0)?)
    })
  }

  fn add_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
  ) -> FutureResult<(), Error> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
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
  ) -> FutureResult<(), Error> {
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
  ) -> FutureResult<(), Error> {
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
  ) -> FutureResult<Vec<WorkspaceMember>, Error> {
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

  fn get_user_awareness_updates(&self, _uid: i64) -> FutureResult<Vec<Vec<u8>>, Error> {
    // TODO(nathan): implement the RESTful API for this
    FutureResult::new(async { Ok(vec![]) })
  }

  fn reset_workspace(&self, _collab_object: CollabObject) -> FutureResult<(), Error> {
    // TODO(nathan): implement the RESTful API for this
    FutureResult::new(async { Ok(()) })
  }

  fn create_collab_object(
    &self,
    collab_object: &CollabObject,
    data: Vec<u8>,
  ) -> FutureResult<(), Error> {
    let try_get_client = self.server.try_get_client();
    let collab_object = collab_object.clone();
    FutureResult::new(async move {
      let client = try_get_client?;
      let params = InsertCollabParams::new(
        collab_object.object_id.clone(),
        collab_object.collab_type.clone(),
        data,
        collab_object.workspace_id.clone(),
      );
      client.create_collab(params).await?;
      Ok(())
    })
  }
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
    name: user_profile.name.unwrap_or_default(),
    latest_workspace,
    user_workspaces,
    email: user_profile.email,
    token: Some(client.get_token()?),
    device_id: params.device_id,
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
    database_views_aggregate_id: af_workspace.database_storage_id.to_string(),
  }
}

fn to_user_workspaces(workspaces: Vec<AFWorkspace>) -> Result<Vec<UserWorkspace>, FlowyError> {
  let mut result = Vec::with_capacity(workspaces.len());
  for item in workspaces.into_iter() {
    result.push(to_user_workspace(item));
  }
  Ok(result)
}

fn oauth_params_from_box_any(any: BoxAny) -> Result<AFCloudOAuthParams, Error> {
  let map: HashMap<String, String> = any.unbox_or_error()?;
  let sign_in_url = map
    .get(USER_SIGN_IN_URL)
    .ok_or_else(|| FlowyError::new(ErrorCode::MissingAuthField, "Missing token field"))?
    .as_str();
  let device_id = map.get(USER_DEVICE_ID).cloned().unwrap_or_default();
  Ok(AFCloudOAuthParams {
    sign_in_url: sign_in_url.to_string(),
    device_id,
  })
}
