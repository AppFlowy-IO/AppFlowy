use std::sync::Arc;

use anyhow::{anyhow, Error};
use client_api::entity::{AFUserProfileView, AFWorkspace, AFWorkspaces, InsertCollabParams};
use collab_define::CollabObject;

use flowy_error::FlowyError;
use flowy_user_deps::cloud::UserCloudService;
use flowy_user_deps::entities::*;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::af_cloud::{AFCloudClient, AFServer};

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
  fn sign_up(&self, params: BoxAny) -> FutureResult<SignUpResponse, Error> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let params = params.unbox_or_error::<SignUpParams>()?;
      let resp = user_sign_up_request(try_get_client?, params).await?;
      Ok(resp)
    })
  }

  fn sign_in(&self, params: BoxAny) -> FutureResult<SignInResponse, Error> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let params = params.unbox_or_error::<SignInParams>()?;
      let resp = user_sign_in_request(try_get_client?, params).await?;
      Ok(resp)
    })
  }

  fn sign_out(&self, _token: Option<String>) -> FutureResult<(), Error> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move { Ok(try_get_client?.write().await.sign_out().await?) })
  }

  fn update_user(
    &self,
    _credential: UserCredentials,
    _params: UpdateUserProfileParams,
  ) -> FutureResult<(), Error> {
    todo!()
  }

  fn get_user_profile(
    &self,
    _credential: UserCredentials,
  ) -> FutureResult<Option<UserProfile>, Error> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let profile = client.write().await.profile().await?;
      let encryption_type = encryption_type_from_profile(&profile);
      Ok(Some(UserProfile {
        email: profile.email.unwrap_or("".to_string()),
        name: profile.name.unwrap_or("".to_string()),
        token: token_from_client(client).await.unwrap_or("".to_string()),
        icon_url: "".to_owned(),
        openai_key: "".to_owned(),
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
      let workspaces = try_get_client?.write().await.workspaces().await?;
      Ok(to_userworkspaces(workspaces)?)
    })
  }

  fn check_user(&self, credential: UserCredentials) -> FutureResult<(), Error> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let token = credential.token.ok_or(anyhow!("expecting token"))?;
      let uuid = credential.uuid.ok_or(anyhow!("expecting uuid"))?;
      let user = try_get_client?
        .write()
        .await
        .user_info(token.as_str())
        .await?;
      if user.id != uuid {
        return Err(anyhow!("invalid user"));
      }
      Ok(())
    })
  }

  fn add_workspace_member(
    &self,
    _user_email: String,
    _workspace_id: String,
  ) -> FutureResult<(), Error> {
    // TODO(nathan): implement the RESTful API for this
    FutureResult::new(async { Ok(()) })
  }

  fn remove_workspace_member(
    &self,
    _user_email: String,
    _workspace_id: String,
  ) -> FutureResult<(), Error> {
    // TODO(nathan): implement the RESTful API for this
    FutureResult::new(async { Ok(()) })
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
        collab_object.uid,
        collab_object.object_id.clone(),
        collab_object.collab_type.clone(),
        data,
        collab_object.workspace_id.clone(),
      );
      client.write().await.create_collab(params).await?;
      Ok(())
    })
  }
}

pub async fn user_sign_up_request(
  client: Arc<AFCloudClient>,
  params: SignUpParams,
) -> Result<SignUpResponse, FlowyError> {
  client
    .read()
    .await
    .sign_up(&params.email, &params.password)
    .await?;

  let sign_in_resp = user_sign_in_request(
    client,
    SignInParams {
      email: params.email,
      password: params.password,
      name: params.name,
      auth_type: params.auth_type,
      device_id: params.device_id,
    },
  )
  .await?;

  Ok(SignUpResponse {
    user_id: sign_in_resp.user_id(),
    name: sign_in_resp.name,
    latest_workspace: sign_in_resp.latest_workspace,
    user_workspaces: sign_in_resp.user_workspaces,
    is_new_user: false, // TODO: how to know?
    email: sign_in_resp.email,
    token: sign_in_resp.token,
    device_id: sign_in_resp.device_id,
    encryption_type: sign_in_resp.encryption_type,
  })
}

pub async fn user_sign_in_request(
  client: Arc<AFCloudClient>,
  params: SignInParams,
) -> Result<SignInResponse, FlowyError> {
  client
    .write()
    .await
    .sign_in_password(&params.email, &params.password)
    .await?;

  let (mut wc1, mut wc2) = tokio::join!(client.write(), client.write());
  let (profile, workspaces) = tokio::try_join!(wc1.profile(), wc2.workspaces())?;

  // https://github.com/AppFlowy-IO/AppFlowy-Cloud/pull/59
  // use the `get_latest` when it's ready
  let _latest_workspace: AFWorkspace = todo!();

  Ok(SignInResponse {
    user_id: profile.uid.ok_or(anyhow!("no uid found"))?,
    name: profile.name.ok_or(anyhow!("no name found"))?,
    latest_workspace: todo!(),
    user_workspaces: to_userworkspaces(workspaces)?,
    email: profile.email,
    token: token_from_client(client).await,
    device_id: "".to_owned(),
    encryption_type: encryption_type_from_profile(&profile),
  })
}

async fn token_from_client(client: Arc<AFCloudClient>) -> Option<String> {
  match client.read().await.token() {
    Some(t) => Some(t.access_token.to_owned()),
    None => None,
  }
}

fn encryption_type_from_profile(profile: &AFUserProfileView) -> EncryptionType {
  match &profile.encryption_sign {
    Some(e) => EncryptionType::SelfEncryption(e.to_string()),
    None => EncryptionType::NoEncryption,
  }
}

fn to_userworkspace(af_workspace: AFWorkspace) -> Result<UserWorkspace, FlowyError> {
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

fn to_userworkspaces(af_workspaces: AFWorkspaces) -> Result<Vec<UserWorkspace>, FlowyError> {
  let mut result = Vec::with_capacity(af_workspaces.len());
  for item in af_workspaces.0.into_iter() {
    let user_workspace = to_userworkspace(item)?;
    result.push(user_workspace);
  }
  Ok(result)
}
