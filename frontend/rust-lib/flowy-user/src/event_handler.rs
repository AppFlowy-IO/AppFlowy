use std::sync::Weak;
use std::{convert::TryInto, sync::Arc};

use serde_json::Value;

use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_sqlite::kv::StorePreferences;
use flowy_user_deps::cloud::UserCloudConfig;
use flowy_user_deps::entities::*;
use lib_dispatch::prelude::*;
use lib_infra::box_any::BoxAny;

use crate::entities::*;
use crate::manager::UserManager;
use crate::notification::{send_notification, UserNotification};
use crate::services::cloud_config::{
  get_cloud_config, get_or_create_cloud_config, save_cloud_config,
};

fn upgrade_manager(manager: AFPluginState<Weak<UserManager>>) -> FlowyResult<Arc<UserManager>> {
  let manager = manager
    .upgrade()
    .ok_or(FlowyError::internal().with_context("The user session is already drop"))?;
  Ok(manager)
}

fn upgrade_store_preferences(
  store: AFPluginState<Weak<StorePreferences>>,
) -> FlowyResult<Arc<StorePreferences>> {
  let store = store
    .upgrade()
    .ok_or(FlowyError::internal().with_context("The store preferences is already drop"))?;
  Ok(store)
}

#[tracing::instrument(level = "debug", name = "sign_in", skip(data, manager), fields(email = %data.email), err)]
pub async fn sign_in(
  data: AFPluginData<SignInPayloadPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: SignInParams = data.into_inner().try_into()?;
  let auth_type = params.auth_type.clone();

  let user_profile: UserProfilePB = manager
    .sign_in(BoxAny::new(params), auth_type)
    .await?
    .into();
  data_result_ok(user_profile)
}

#[tracing::instrument(
    level = "debug",
    name = "sign_up",
    skip(data, manager),
    fields(
        email = %data.email,
        name = %data.name,
    ),
    err
)]
pub async fn sign_up(
  data: AFPluginData<SignUpPayloadPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: SignUpParams = data.into_inner().try_into()?;
  let auth_type = params.auth_type.clone();

  let user_profile = manager.sign_up(auth_type, BoxAny::new(params)).await?;
  data_result_ok(user_profile.into())
}

#[tracing::instrument(level = "debug", skip(manager))]
pub async fn init_user_handler(
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  manager.init_user().await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(manager))]
pub async fn check_user_handler(
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  manager.check_user().await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(manager))]
pub async fn get_user_profile_handler(
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let uid = manager.get_session()?.user_id;
  let user_profile = manager.get_user_profile(uid).await?;

  let weak_manager = Arc::downgrade(&manager);
  let cloned_user_profile = user_profile.clone();
  tokio::spawn(async move {
    if let Some(manager) = weak_manager.upgrade() {
      let _ = manager.refresh_user_profile(&cloned_user_profile).await;
    }
  });

  data_result_ok(user_profile.into())
}

#[tracing::instrument(level = "debug", skip(manager))]
pub async fn sign_out(manager: AFPluginState<Weak<UserManager>>) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  manager.sign_out().await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager))]
pub async fn update_user_profile_handler(
  data: AFPluginData<UpdateUserProfilePayloadPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: UpdateUserProfileParams = data.into_inner().try_into()?;
  manager.update_user_profile(params).await?;
  Ok(())
}

const APPEARANCE_SETTING_CACHE_KEY: &str = "appearance_settings";

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn set_appearance_setting(
  store_preferences: AFPluginState<Weak<StorePreferences>>,
  data: AFPluginData<AppearanceSettingsPB>,
) -> Result<(), FlowyError> {
  let store_preferences = upgrade_store_preferences(store_preferences)?;
  let mut setting = data.into_inner();
  if setting.theme.is_empty() {
    setting.theme = APPEARANCE_DEFAULT_THEME.to_string();
  }

  store_preferences.set_object(APPEARANCE_SETTING_CACHE_KEY, setting)?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn get_appearance_setting(
  store_preferences: AFPluginState<Weak<StorePreferences>>,
) -> DataResult<AppearanceSettingsPB, FlowyError> {
  let store_preferences = upgrade_store_preferences(store_preferences)?;
  match store_preferences.get_str(APPEARANCE_SETTING_CACHE_KEY) {
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
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<UserSettingPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let user_setting = manager.user_setting()?;
  data_result_ok(user_setting)
}

/// Only used for third party auth.
/// Use [UserEvent::SignIn] or [UserEvent::SignUp] If the [AuthType] is Local or SelfHosted
#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub async fn third_party_auth_handler(
  data: AFPluginData<ThirdPartyAuthPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.into_inner();
  let auth_type: AuthType = params.auth_type.into();
  let user_profile = manager.sign_up(auth_type, BoxAny::new(params.map)).await?;
  data_result_ok(user_profile.into())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn set_encrypt_secret_handler(
  manager: AFPluginState<Weak<UserManager>>,
  data: AFPluginData<UserSecretPB>,
  store_preferences: AFPluginState<Weak<StorePreferences>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let store_preferences = upgrade_store_preferences(store_preferences)?;
  let data = data.into_inner();
  match data.encryption_type {
    EncryptionTypePB::NoEncryption => {
      tracing::error!("Encryption type is NoEncryption, but set encrypt secret");
    },
    EncryptionTypePB::Symmetric => {
      manager.check_encryption_sign_with_secret(
        data.user_id,
        &data.encryption_sign,
        &data.encryption_secret,
      )?;

      let config = UserCloudConfig::new(data.encryption_secret).with_enable_encrypt(true);
      manager
        .set_encrypt_secret(
          data.user_id,
          config.encrypt_secret.clone(),
          EncryptionType::SelfEncryption(data.encryption_sign),
        )
        .await?;
      save_cloud_config(data.user_id, &store_preferences, config)?;
    },
  }

  manager.resume_sign_up().await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn check_encrypt_secret_handler(
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<UserEncryptionSecretCheckPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let uid = manager.get_session()?.user_id;
  let profile = manager.get_user_profile(uid).await?;

  let is_need_secret = match profile.encryption_type {
    EncryptionType::NoEncryption => false,
    EncryptionType::SelfEncryption(sign) => {
      if sign.is_empty() {
        false
      } else {
        manager.check_encryption_sign(uid, &sign).is_err()
      }
    },
  };

  data_result_ok(UserEncryptionSecretCheckPB { is_need_secret })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn set_cloud_config_handler(
  manager: AFPluginState<Weak<UserManager>>,
  data: AFPluginData<UpdateCloudConfigPB>,
  store_preferences: AFPluginState<Weak<StorePreferences>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let session = manager.get_session()?;
  let update = data.into_inner();
  let store_preferences = upgrade_store_preferences(store_preferences)?;
  let mut config = get_cloud_config(session.user_id, &store_preferences)
    .ok_or(FlowyError::internal().with_context("Can't find any cloud config"))?;

  if let Some(enable_sync) = update.enable_sync {
    manager.cloud_services.set_enable_sync(enable_sync);
    config.enable_sync = enable_sync;
  }

  if let Some(enable_encrypt) = update.enable_encrypt {
    debug_assert!(enable_encrypt, "Disable encryption is not supported");

    if enable_encrypt {
      tracing::info!("Enable encryption for user: {}", session.user_id);
      config = config.with_enable_encrypt(enable_encrypt);
      let encrypt_secret = config.encrypt_secret.clone();

      // The encryption secret is generated when the user first enables encryption and will be
      // used to validate the encryption secret is correct when the user logs in.
      let encryption_sign = manager.generate_encryption_sign(session.user_id, &encrypt_secret)?;
      let encryption_type = EncryptionType::SelfEncryption(encryption_sign);
      manager
        .set_encrypt_secret(session.user_id, encrypt_secret, encryption_type.clone())
        .await?;
      save_cloud_config(session.user_id, &store_preferences, config.clone())?;

      let params =
        UpdateUserProfileParams::new(session.user_id).with_encryption_type(encryption_type);
      manager.update_user_profile(params).await?;
    }
  }

  let config_pb = UserCloudConfigPB::from(config);
  send_notification(
    &session.user_id.to_string(),
    UserNotification::DidUpdateCloudConfig,
  )
  .payload(config_pb)
  .send();
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn get_cloud_config_handler(
  manager: AFPluginState<Weak<UserManager>>,
  store_preferences: AFPluginState<Weak<StorePreferences>>,
) -> DataResult<UserCloudConfigPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let session = manager.get_session()?;

  let store_preferences = upgrade_store_preferences(store_preferences)?;
  // Generate the default config if the config is not exist
  let config = get_or_create_cloud_config(session.user_id, &store_preferences);
  data_result_ok(config.into())
}

#[tracing::instrument(level = "debug", skip(manager), err)]
pub async fn get_all_user_workspace_handler(
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<RepeatedUserWorkspacePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let uid = manager.get_session()?.user_id;
  let user_workspaces = manager.get_all_user_workspaces(uid)?;
  data_result_ok(user_workspaces.into())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub async fn open_workspace_handler(
  data: AFPluginData<UserWorkspacePB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.into_inner();
  manager.open_workspace(&params.id).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub async fn add_user_to_workspace_handler(
  data: AFPluginData<AddWorkspaceUserPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.into_inner();
  manager
    .add_user_to_workspace(params.email, params.workspace_id)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub async fn remove_user_from_workspace_handler(
  data: AFPluginData<RemoveWorkspaceUserPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.into_inner();
  manager
    .remove_user_to_workspace(params.email, params.workspace_id)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub async fn update_network_state_handler(
  data: AFPluginData<NetworkStatePB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let reachable = data.into_inner().ty.is_reachable();
  manager
    .user_status_callback
    .read()
    .await
    .did_update_network(reachable);
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn get_historical_users_handler(
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<RepeatedHistoricalUserPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let users = RepeatedHistoricalUserPB::from(manager.get_historical_users());
  data_result_ok(users)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn open_historical_users_handler(
  user: AFPluginData<HistoricalUserPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let user = user.into_inner();
  let manager = upgrade_manager(manager)?;
  let auth_type = AuthType::from(user.auth_type);
  manager
    .open_historical_user(user.user_id, user.device_id, auth_type)
    .await?;
  Ok(())
}

pub async fn push_realtime_event_handler(
  payload: AFPluginData<RealtimePayloadPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  match serde_json::from_str::<Value>(&payload.into_inner().json_str) {
    Ok(json) => {
      let manager = upgrade_manager(manager)?;
      manager.receive_realtime_event(json).await;
    },
    Err(e) => {
      tracing::error!("Deserialize RealtimePayload failed: {:?}", e);
    },
  }
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn create_reminder_event_handler(
  data: AFPluginData<ReminderPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.into_inner();
  manager.add_reminder(params).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn get_all_reminder_event_handler(
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<RepeatedReminderPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let reminders = manager
    .get_all_reminders()
    .await
    .into_iter()
    .map(ReminderPB::from)
    .collect::<Vec<_>>();
  data_result_ok(reminders.into())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn reset_workspace_handler(
  data: AFPluginData<ResetWorkspacePB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let reset_pb = data.into_inner();
  if reset_pb.workspace_id.is_empty() {
    return Err(FlowyError::new(
      ErrorCode::WorkspaceIdInvalid,
      "The workspace id is empty",
    ));
  }
  manager.reset_workspace(reset_pb).await?;
  Ok(())
}
