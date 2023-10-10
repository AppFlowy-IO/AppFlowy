use std::collections::HashMap;
use std::sync::Arc;

use anyhow::{anyhow, Error};
use client_api::entity::dto::UserUpdateParams;
use client_api::entity::{
  AFUserProfileView, AFWorkspace, AFWorkspaces, InsertCollabParams, OAuthProvider,
};
use collab_entity::CollabObject;

use flowy_error::{ErrorCode, FlowyError};
use flowy_user_deps::cloud::UserCloudService;
use flowy_user_deps::entities::*;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

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
        .update(UserUpdateParams {
          name: params.name,
          email: params.email,
          password: params.password,
        })
        .await?;
      Ok(())
    })
  }

  fn get_user_profile(
    &self,
    _credential: UserCredentials,
  ) -> FutureResult<Option<UserProfile>, Error> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let profile = client.profile().await?;
      let encryption_type = encryption_type_from_profile(&profile);
      Ok(Some(UserProfile {
        email: profile.email.unwrap_or("".to_string()),
        name: profile.name.unwrap_or("".to_string()),
        token: client.get_token()?,
        icon_url: "".to_owned(),
        openai_key: "".to_owned(),
        stability_ai_key: "".to_owned(),
        workspace_id: match profile.latest_workspace_id {
          Some(w) => w.to_string(),
          None => "".to_string(),
        },
        auth_type: AuthType::AFCloud,
        encryption_type,
        uid: profile.uid.ok_or(anyhow!("no uid found"))?,
      }))
    })
  }

  fn get_user_workspaces(&self, _uid: i64) -> FutureResult<Vec<UserWorkspace>, Error> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let workspaces = try_get_client?.workspaces().await?;
      Ok(to_user_workspaces(workspaces)?)
    })
  }

  fn check_user(&self, credential: UserCredentials) -> FutureResult<(), Error> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      // from params
      let token = credential.token.ok_or(anyhow!("expecting token"))?;
      let uid = credential.uid.ok_or(anyhow!("expecting uid"))?;

      // from cloud
      let client = try_get_client?;
      let profile = client.profile().await?;
      let client_token = client.access_token()?;

      // compare and check
      if uid != profile.uid.ok_or(anyhow!("expecting uid"))? {
        return Err(anyhow!("uid mismatch"));
      }
      if token != client_token {
        return Err(anyhow!("token mismatch"));
      }
      Ok(())
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
        .add_workspace_members(workspace_id.parse()?, vec![user_email])
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
        .remove_workspace_members(workspace_id.parse()?, vec![user_email])
        .await?;
      Ok(())
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
  let (profile, af_workspaces) = tokio::try_join!(client.profile(), client.workspaces())?;

  let latest_workspace = to_user_workspace(
    af_workspaces
      .get_latest(&profile)
      .or(af_workspaces.first().cloned())
      .ok_or(anyhow!("no workspace found"))?,
  )?;

  let user_workspaces = to_user_workspaces(af_workspaces)?;
  let encryption_type = encryption_type_from_profile(&profile);

  Ok(AuthResponse {
    user_id: profile.uid.ok_or(anyhow!("no uid found"))?,
    name: profile.name.ok_or(anyhow!("no name found"))?,
    latest_workspace,
    user_workspaces,
    email: profile.email,
    token: Some(client.get_token()?),
    device_id: params.device_id,
    encryption_type,
    is_new_user,
  })
}

fn encryption_type_from_profile(profile: &AFUserProfileView) -> EncryptionType {
  match &profile.encryption_sign {
    Some(e) => EncryptionType::SelfEncryption(e.to_string()),
    None => EncryptionType::NoEncryption,
  }
}

fn to_user_workspace(af_workspace: AFWorkspace) -> Result<UserWorkspace, FlowyError> {
  Ok(UserWorkspace {
    id: af_workspace.workspace_id.to_string(),
    name: af_workspace
      .workspace_name
      .ok_or(anyhow!("no workspace_name found"))?,
    created_at: af_workspace
      .created_at
      .ok_or(anyhow!("no created_at found"))?,
    database_views_aggregate_id: af_workspace
      .database_storage_id
      .ok_or(anyhow!("no database_views_aggregate_id found"))?
      .to_string(),
  })
}

fn to_user_workspaces(af_workspaces: AFWorkspaces) -> Result<Vec<UserWorkspace>, FlowyError> {
  let mut result = Vec::with_capacity(af_workspaces.len());
  for item in af_workspaces.0.into_iter() {
    let user_workspace = to_user_workspace(item)?;
    result.push(user_workspace);
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
