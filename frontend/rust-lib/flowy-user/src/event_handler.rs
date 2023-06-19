use std::{convert::TryInto, sync::Arc};

use flowy_error::FlowyError;
use flowy_sqlite::kv::KV;
use lib_dispatch::prelude::*;
use lib_infra::box_any::BoxAny;

use crate::entities::*;
use crate::entities::{SignInParams, SignUpParams, UpdateUserProfileParams};
use crate::services::{AuthType, UserSession};

#[tracing::instrument(level = "debug", name = "sign_in", skip(data, session), fields(email = %data.email), err)]
pub async fn sign_in(
  data: AFPluginData<SignInPayloadPB>,
  session: AFPluginState<Arc<UserSession>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let params: SignInParams = data.into_inner().try_into()?;
  let auth_type = params.auth_type.clone();

  let user_profile: UserProfilePB = session
    .sign_in(&auth_type, BoxAny::new(params))
    .await?
    .into();
  data_result_ok(user_profile)
}

#[tracing::instrument(
    level = "debug",
    name = "sign_up",
    skip(data, session),
    fields(
        email = %data.email,
        name = %data.name,
    ),
    err
)]
pub async fn sign_up(
  data: AFPluginData<SignUpPayloadPB>,
  session: AFPluginState<Arc<UserSession>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let params: SignUpParams = data.into_inner().try_into()?;
  let auth_type = params.auth_type.clone();
  let user_profile: UserProfilePB = session
    .sign_up(&auth_type, BoxAny::new(params))
    .await?
    .into();
  data_result_ok(user_profile)
}

#[tracing::instrument(level = "debug", skip(session))]
pub async fn init_user_handler(session: AFPluginState<Arc<UserSession>>) -> Result<(), FlowyError> {
  session.init_user().await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(session))]
pub async fn check_user_handler(
  session: AFPluginState<Arc<UserSession>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let user_profile: UserProfilePB = session.check_user().await?.into();
  data_result_ok(user_profile)
}

#[tracing::instrument(level = "debug", skip(session))]
pub async fn get_user_profile_handler(
  session: AFPluginState<Arc<UserSession>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let user_profile: UserProfilePB = session.get_user_profile().await?.into();
  data_result_ok(user_profile)
}

#[tracing::instrument(level = "debug", skip(data, session))]
pub async fn sign_out(
  data: AFPluginData<SignOutPB>,
  session: AFPluginState<Arc<UserSession>>,
) -> Result<(), FlowyError> {
  let auth_type: AuthType = data.into_inner().auth_type.into();
  session.sign_out(&auth_type).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, session))]
pub async fn update_user_profile_handler(
  data: AFPluginData<UpdateUserProfilePayloadPB>,
  session: AFPluginState<Arc<UserSession>>,
) -> Result<(), FlowyError> {
  let params: UpdateUserProfileParams = data.into_inner().try_into()?;
  session.update_user_profile(params).await?;
  Ok(())
}

const APPEARANCE_SETTING_CACHE_KEY: &str = "appearance_settings";

#[tracing::instrument(level = "debug", skip(data), err)]
pub async fn set_appearance_setting(
  data: AFPluginData<AppearanceSettingsPB>,
) -> Result<(), FlowyError> {
  let mut setting = data.into_inner();
  if setting.theme.is_empty() {
    setting.theme = APPEARANCE_DEFAULT_THEME.to_string();
  }

  KV::set_object(APPEARANCE_SETTING_CACHE_KEY, setting)?;
  Ok(())
}

#[tracing::instrument(level = "debug", err)]
pub async fn get_appearance_setting() -> DataResult<AppearanceSettingsPB, FlowyError> {
  match KV::get_str(APPEARANCE_SETTING_CACHE_KEY) {
    None => data_result_ok(AppearanceSettingsPB::default()),
    Some(s) => {
      let setting = match serde_json::from_str(&s) {
        Ok(setting) => setting,
        Err(e) => {
          tracing::error!(
            "Deserialize AppearanceSettings failed: {:?}, fallback to default",
            e
          );
          AppearanceSettingsPB::default()
        },
      };
      data_result_ok(setting)
    },
  }
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn get_user_setting(
  session: AFPluginState<Arc<UserSession>>,
) -> DataResult<UserSettingPB, FlowyError> {
  let user_setting = session.user_setting()?;
  data_result_ok(user_setting)
}

/// Only used for third party auth.
/// Use [UserEvent::SignIn] or [UserEvent::SignUp] If the [AuthType] is Local or SelfHosted
#[tracing::instrument(level = "debug", skip(data, session), err)]
pub async fn third_party_auth_handler(
  data: AFPluginData<ThirdPartyAuthPB>,
  session: AFPluginState<Arc<UserSession>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let params = data.into_inner();
  let auth_type: AuthType = params.auth_type.into();
  let user_profile: UserProfilePB = session
    .sign_up(&auth_type, BoxAny::new(params.map))
    .await?
    .into();
  data_result_ok(user_profile)
}
