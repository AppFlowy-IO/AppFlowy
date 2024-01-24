use flowy_error::FlowyError;
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};
use std::sync::Weak;

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub async fn oauth_sign_in_handler(
  data: AFPluginData<OauthSignInPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.into_inner();
  let authenticator: Authenticator = params.authenticator.into();
  let user_profile = manager
    .sign_up(authenticator, BoxAny::new(params.map))
    .await?;
  data_result_ok(user_profile.into())
}
