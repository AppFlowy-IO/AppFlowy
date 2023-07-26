use std::convert::TryFrom;
use std::sync::Weak;
use std::{convert::TryInto, sync::Arc};

use flowy_error::{FlowyError, FlowyResult};
use flowy_server_config::supabase_config::SupabaseConfiguration;
use flowy_sqlite::kv::KV;
use flowy_user_deps::entities::*;
use lib_dispatch::prelude::*;
use lib_infra::box_any::BoxAny;

use crate::entities::*;
use crate::services::{get_supabase_config, UserSession};

fn upgrade_session(session: AFPluginState<Weak<UserSession>>) -> FlowyResult<Arc<UserSession>> {
  let session = session
    .upgrade()
    .ok_or(FlowyError::internal().context("The user session is already drop"))?;
  Ok(session)
}

#[tracing::instrument(level = "debug", name = "sign_in", skip(data, session), fields(email = %data.email), err)]
pub async fn sign_in(
  data: AFPluginData<SignInPayloadPB>,
  session: AFPluginState<Weak<UserSession>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let session = upgrade_session(session)?;
  let params: SignInParams = data.into_inner().try_into()?;
  let auth_type = params.auth_type.clone();
  session.update_auth_type(&auth_type).await;

  let user_profile: UserProfilePB = session
    .sign_in(BoxAny::new(params), auth_type)
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
  session: AFPluginState<Weak<UserSession>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let session = upgrade_session(session)?;
  let params: SignUpParams = data.into_inner().try_into()?;
  let auth_type = params.auth_type.clone();
  session.update_auth_type(&auth_type).await;

  let user_profile = session.sign_up(auth_type, BoxAny::new(params)).await?;
  data_result_ok(user_profile.into())
}

#[tracing::instrument(level = "debug", skip(session))]
pub async fn init_user_handler(
  session: AFPluginState<Weak<UserSession>>,
) -> Result<(), FlowyError> {
  let session = upgrade_session(session)?;
  session.init_user().await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(session))]
pub async fn check_user_handler(
  session: AFPluginState<Weak<UserSession>>,
) -> Result<(), FlowyError> {
  let session = upgrade_session(session)?;
  session.check_user().await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(session))]
pub async fn get_user_profile_handler(
  session: AFPluginState<Weak<UserSession>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let session = upgrade_session(session)?;
  let uid = session.get_session()?.user_id;
  let user_profile: UserProfilePB = session.get_user_profile(uid, true).await?.into();
  data_result_ok(user_profile)
}

#[tracing::instrument(level = "debug", skip(session))]
pub async fn sign_out(session: AFPluginState<Weak<UserSession>>) -> Result<(), FlowyError> {
  let session = upgrade_session(session)?;
  session.sign_out().await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, session))]
pub async fn update_user_profile_handler(
  data: AFPluginData<UpdateUserProfilePayloadPB>,
  session: AFPluginState<Weak<UserSession>>,
) -> Result<(), FlowyError> {
  let session = upgrade_session(session)?;
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
  session: AFPluginState<Weak<UserSession>>,
) -> DataResult<UserSettingPB, FlowyError> {
  let session = upgrade_session(session)?;
  let user_setting = session.user_setting()?;
  data_result_ok(user_setting)
}

/// Only used for third party auth.
/// Use [UserEvent::SignIn] or [UserEvent::SignUp] If the [AuthType] is Local or SelfHosted
#[tracing::instrument(level = "debug", skip(data, session), err)]
pub async fn third_party_auth_handler(
  data: AFPluginData<ThirdPartyAuthPB>,
  session: AFPluginState<Weak<UserSession>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let session = upgrade_session(session)?;
  let params = data.into_inner();
  let auth_type: AuthType = params.auth_type.into();
  session.update_auth_type(&auth_type).await;
  let user_profile = session.sign_up(auth_type, BoxAny::new(params.map)).await?;
  data_result_ok(user_profile.into())
}

#[tracing::instrument(level = "debug", skip(data, session), err)]
pub async fn set_supabase_config_handler(
  data: AFPluginData<SupabaseConfigPB>,
  session: AFPluginState<Weak<UserSession>>,
) -> Result<(), FlowyError> {
  let session = upgrade_session(session)?;
  let config = SupabaseConfiguration::try_from(data.into_inner())?;
  session.save_supabase_config(config);
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn get_supabase_config_handler(
  _session: AFPluginState<Weak<UserSession>>,
) -> DataResult<SupabaseConfigPB, FlowyError> {
  let config = get_supabase_config().unwrap_or_default();
  data_result_ok(config.into())
}

#[tracing::instrument(level = "debug", skip(session), err)]
pub async fn get_all_user_workspace_handler(
  session: AFPluginState<Weak<UserSession>>,
) -> DataResult<RepeatedUserWorkspacePB, FlowyError> {
  let session = upgrade_session(session)?;
  let uid = session.get_session()?.user_id;
  let user_workspaces = session.get_all_user_workspaces(uid)?;
  data_result_ok(user_workspaces.into())
}

#[tracing::instrument(level = "debug", skip(data, session), err)]
pub async fn open_workspace_handler(
  data: AFPluginData<UserWorkspacePB>,
  session: AFPluginState<Weak<UserSession>>,
) -> Result<(), FlowyError> {
  let session = upgrade_session(session)?;
  let params = data.into_inner();
  session.open_workspace(&params.id).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, session), err)]
pub async fn add_user_to_workspace_handler(
  data: AFPluginData<AddWorkspaceUserPB>,
  session: AFPluginState<Weak<UserSession>>,
) -> Result<(), FlowyError> {
  let session = upgrade_session(session)?;
  let params = data.into_inner();
  session
    .add_user_to_workspace(params.email, params.workspace_id)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, session), err)]
pub async fn remove_user_from_workspace_handler(
  data: AFPluginData<RemoveWorkspaceUserPB>,
  session: AFPluginState<Weak<UserSession>>,
) -> Result<(), FlowyError> {
  let session = upgrade_session(session)?;
  let params = data.into_inner();
  session
    .remove_user_to_workspace(params.email, params.workspace_id)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, session), err)]
pub async fn update_network_state_handler(
  data: AFPluginData<NetworkStatePB>,
  session: AFPluginState<Weak<UserSession>>,
) -> Result<(), FlowyError> {
  let session = upgrade_session(session)?;
  let reachable = data.into_inner().ty.is_reachable();
  session
    .user_status_callback
    .read()
    .await
    .did_update_network(reachable);
  Ok(())
}
