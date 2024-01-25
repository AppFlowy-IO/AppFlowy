use crate::entities::{OauthSignInPB, UserProfilePB};
use crate::manager::UserManagerWASM;
use flowy_error::{FlowyError, FlowyResult};
use flowy_user_pub::entities::Authenticator;
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};
use lib_infra::box_any::BoxAny;
use std::sync::{Arc, Weak};

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub async fn oauth_sign_in_handler(
  data: AFPluginData<OauthSignInPB>,
  manager: AFPluginState<Weak<UserManagerWASM>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.into_inner();
  let authenticator: Authenticator = params.authenticator.into();
  let user_profile = manager
    .sign_up(authenticator, BoxAny::new(params.map))
    .await?;
  data_result_ok(user_profile.into())
}

fn upgrade_manager(
  manager: AFPluginState<Weak<UserManagerWASM>>,
) -> FlowyResult<Arc<UserManagerWASM>> {
  let manager = manager
    .upgrade()
    .ok_or(FlowyError::internal().with_context("The user session is already drop"))?;
  Ok(manager)
}
