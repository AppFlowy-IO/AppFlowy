use std::sync::Arc;

use anyhow::{anyhow, Error};
use collab_define::CollabObject;

use flowy_error::FlowyError;
use flowy_user_deps::cloud::UserCloudService;
use flowy_user_deps::entities::*;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;
use storage_entity::{AFWorkspace, AFWorkspaces};

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

  fn sign_in(&self, _params: BoxAny) -> FutureResult<SignInResponse, Error> {
    todo!()
  }

  fn sign_out(&self, _token: Option<String>) -> FutureResult<(), Error> {
    todo!()
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
    todo!()
  }

  fn get_user_workspaces(
    &self,
    _uid: i64,
  ) -> FutureResult<std::vec::Vec<flowy_user_deps::entities::UserWorkspace>, Error> {
    // TODO(nathan): implement the RESTful API for this
    todo!()
  }

  fn check_user(&self, _credential: UserCredentials) -> FutureResult<(), Error> {
    // TODO(nathan): implement the RESTful API for this
    FutureResult::new(async { Ok(()) })
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
    _collab_object: &CollabObject,
    _data: Vec<u8>,
  ) -> FutureResult<(), Error> {
    // TODO(nathan): implement the RESTful API for this
    FutureResult::new(async { Ok(()) })
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
    token: match client.read().await.token() {
      Some(t) => Some(t.access_token.to_owned()),
      None => None,
    },
    device_id: "".to_owned(),
    encryption_type: match profile.encryption_sign {
      Some(e) => EncryptionType::SelfEncryption(e),
      None => EncryptionType::NoEncryption,
    },
  })
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
