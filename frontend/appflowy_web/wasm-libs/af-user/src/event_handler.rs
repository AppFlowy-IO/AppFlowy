use crate::entities::*;
use crate::manager::UserManagerWASM;
use flowy_error::{FlowyError, FlowyResult};
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};
use lib_infra::box_any::BoxAny;
use std::rc::{Rc, Weak};

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub async fn oauth_sign_in_handler(
  data: AFPluginData<OauthSignInPB>,
  manager: AFPluginState<Weak<UserManagerWASM>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.into_inner();
  let user_profile = manager.sign_up(BoxAny::new(params.map)).await?;
  data_result_ok(user_profile.into())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub async fn add_user_handler(
  data: AFPluginData<AddUserPB>,
  manager: AFPluginState<Weak<UserManagerWASM>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.into_inner();
  manager.add_user(&params.email, &params.password).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub async fn sign_in_with_password_handler(
  data: AFPluginData<UserSignInPB>,
  manager: AFPluginState<Weak<UserManagerWASM>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.into_inner();
  let user_profile = manager
    .sign_in_with_password(&params.email, &params.password)
    .await?;
  data_result_ok(UserProfilePB::from(user_profile))
}

fn upgrade_manager(
  manager: AFPluginState<Weak<UserManagerWASM>>,
) -> FlowyResult<Rc<UserManagerWASM>> {
  let manager = manager
    .upgrade()
    .ok_or(FlowyError::internal().with_context("The user session is already drop"))?;
  Ok(manager)
}
