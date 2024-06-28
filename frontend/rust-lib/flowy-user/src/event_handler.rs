use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_sqlite::kv::KVStorePreferences;
use flowy_user_pub::cloud::UserCloudConfig;
use flowy_user_pub::entities::*;
use lib_dispatch::prelude::*;
use lib_infra::box_any::BoxAny;
use serde_json::Value;
use std::sync::Weak;
use std::{convert::TryInto, sync::Arc};
use tracing::{event, trace};

use crate::entities::*;
use crate::notification::{send_notification, UserNotification};
use crate::services::cloud_config::{
  get_cloud_config, get_or_create_cloud_config, save_cloud_config,
};
use crate::services::data_import::prepare_import;
use crate::user_manager::UserManager;

fn upgrade_manager(manager: AFPluginState<Weak<UserManager>>) -> FlowyResult<Arc<UserManager>> {
  let manager = manager
    .upgrade()
    .ok_or(FlowyError::internal().with_context("The user session is already drop"))?;
  Ok(manager)
}

fn upgrade_store_preferences(
  store: AFPluginState<Weak<KVStorePreferences>>,
) -> FlowyResult<Arc<KVStorePreferences>> {
  let store = store
    .upgrade()
    .ok_or(FlowyError::internal().with_context("The store preferences is already drop"))?;
  Ok(store)
}

#[tracing::instrument(level = "debug", name = "sign_in", skip(data, manager), fields(email = %data.email), err)]
pub async fn sign_in_with_email_password_handler(
  data: AFPluginData<SignInPayloadPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: SignInParams = data.into_inner().try_into()?;
  let auth_type = params.auth_type.clone();

  let old_authenticator = manager.cloud_services.get_user_authenticator();
  match manager.sign_in(params, auth_type).await {
    Ok(profile) => data_result_ok(UserProfilePB::from(profile)),
    Err(err) => {
      manager
        .cloud_services
        .set_user_authenticator(&old_authenticator);
      return Err(err);
    },
  }
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
  let authenticator = params.auth_type.clone();

  let old_authenticator = manager.cloud_services.get_user_authenticator();
  match manager.sign_up(authenticator, BoxAny::new(params)).await {
    Ok(profile) => data_result_ok(UserProfilePB::from(profile)),
    Err(err) => {
      manager
        .cloud_services
        .set_user_authenticator(&old_authenticator);
      return Err(err);
    },
  }
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
pub async fn get_user_profile_handler(
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let uid = manager.get_session()?.user_id;
  let mut user_profile = manager.get_user_profile_from_disk(uid).await?;

  let weak_manager = Arc::downgrade(&manager);
  let cloned_user_profile = user_profile.clone();

  // Refresh the user profile in the background
  af_spawn(async move {
    if let Some(manager) = weak_manager.upgrade() {
      let _ = manager.refresh_user_profile(&cloned_user_profile).await;
    }
  });

  // When the user is logged in with a local account, the email field is a placeholder and should
  // not be exposed to the client. So we set the email field to an empty string.
  if user_profile.authenticator == Authenticator::Local {
    user_profile.email = "".to_string();
  }

  data_result_ok(user_profile.into())
}

#[tracing::instrument(level = "debug", skip(manager))]
pub async fn sign_out_handler(manager: AFPluginState<Weak<UserManager>>) -> Result<(), FlowyError> {
  let (tx, rx) = tokio::sync::oneshot::channel();
  tokio::spawn(async move {
    let result = async {
      let manager = upgrade_manager(manager)?;
      manager.sign_out().await?;
      Ok::<(), FlowyError>(())
    }
    .await;
    let _ = tx.send(result);
  });
  rx.await??;
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
  store_preferences: AFPluginState<Weak<KVStorePreferences>>,
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
  store_preferences: AFPluginState<Weak<KVStorePreferences>>,
) -> DataResult<AppearanceSettingsPB, FlowyError> {
  let store_preferences = upgrade_store_preferences(store_preferences)?;
  match store_preferences.get_str(APPEARANCE_SETTING_CACHE_KEY) {
    None => data_result_ok(AppearanceSettingsPB::default()),
    Some(s) => {
      let setting = serde_json::from_str(&s).unwrap_or_else(|err| {
        tracing::error!(
          "Deserialize AppearanceSettings failed: {:?}, fallback to default",
          err
        );
        AppearanceSettingsPB::default()
      });
      data_result_ok(setting)
    },
  }
}

const DATE_TIME_SETTINGS_CACHE_KEY: &str = "date_time_settings";

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn set_date_time_settings(
  store_preferences: AFPluginState<Weak<KVStorePreferences>>,
  data: AFPluginData<DateTimeSettingsPB>,
) -> Result<(), FlowyError> {
  let store_preferences = upgrade_store_preferences(store_preferences)?;
  let mut setting = data.into_inner();
  if setting.timezone_id.is_empty() {
    setting.timezone_id = "".to_string();
  }

  store_preferences.set_object(DATE_TIME_SETTINGS_CACHE_KEY, setting)?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn get_date_time_settings(
  store_preferences: AFPluginState<Weak<KVStorePreferences>>,
) -> DataResult<DateTimeSettingsPB, FlowyError> {
  let store_preferences = upgrade_store_preferences(store_preferences)?;
  match store_preferences.get_str(DATE_TIME_SETTINGS_CACHE_KEY) {
    None => data_result_ok(DateTimeSettingsPB::default()),
    Some(s) => {
      let setting = match serde_json::from_str(&s) {
        Ok(setting) => setting,
        Err(e) => {
          tracing::error!(
            "Deserialize DateTimeSettings failed: {:?}, fallback to default",
            e
          );
          DateTimeSettingsPB::default()
        },
      };
      data_result_ok(setting)
    },
  }
}

const NOTIFICATION_SETTINGS_CACHE_KEY: &str = "notification_settings";

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn set_notification_settings(
  store_preferences: AFPluginState<Weak<KVStorePreferences>>,
  data: AFPluginData<NotificationSettingsPB>,
) -> Result<(), FlowyError> {
  let store_preferences = upgrade_store_preferences(store_preferences)?;
  let setting = data.into_inner();
  store_preferences.set_object(NOTIFICATION_SETTINGS_CACHE_KEY, setting)?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn get_notification_settings(
  store_preferences: AFPluginState<Weak<KVStorePreferences>>,
) -> DataResult<NotificationSettingsPB, FlowyError> {
  let store_preferences = upgrade_store_preferences(store_preferences)?;
  match store_preferences.get_str(NOTIFICATION_SETTINGS_CACHE_KEY) {
    None => data_result_ok(NotificationSettingsPB::default()),
    Some(s) => {
      let setting = serde_json::from_str(&s).unwrap_or_else(|e| {
        tracing::error!(
          "Deserialize NotificationSettings failed: {:?}, fallback to default",
          e
        );
        NotificationSettingsPB::default()
      });
      data_result_ok(setting)
    },
  }
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn import_appflowy_data_folder_handler(
  data: AFPluginData<ImportAppFlowyDataPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let data = data.try_into_inner()?;
  let (tx, rx) = tokio::sync::oneshot::channel();
  af_spawn(async move {
    let result = async {
      let manager = upgrade_manager(manager)?;
      let imported_folder = prepare_import(&data.path)
        .map_err(|err| FlowyError::new(ErrorCode::AppFlowyDataFolderImportError, err.to_string()))?
        .with_container_name(data.import_container_name);

      manager.perform_import(imported_folder).await?;
      Ok::<(), FlowyError>(())
    }
    .await;
    let _ = tx.send(result);
  });
  rx.await??;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn get_user_setting(
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<UserSettingPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let user_setting = manager.user_setting()?;
  data_result_ok(user_setting)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub async fn sign_in_with_magic_link_handler(
  data: AFPluginData<MagicLinkSignInPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.into_inner();
  manager
    .sign_in_with_magic_link(&params.email, &params.redirect_to)
    .await?;
  Ok(())
}

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

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub async fn gen_sign_in_url_handler(
  data: AFPluginData<SignInUrlPayloadPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<SignInUrlPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.into_inner();
  let authenticator: Authenticator = params.authenticator.into();
  let sign_in_url = manager
    .generate_sign_in_url_with_email(&authenticator, &params.email)
    .await?;
  data_result_ok(SignInUrlPB { sign_in_url })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn sign_in_with_provider_handler(
  data: AFPluginData<OauthProviderPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<OauthProviderDataPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  tracing::debug!("Sign in with provider: {:?}", data.provider.as_str());
  let sign_in_url = manager.generate_oauth_url(data.provider.as_str()).await?;
  event!(tracing::Level::DEBUG, "Sign in url: {}", sign_in_url);
  data_result_ok(OauthProviderDataPB {
    oauth_url: sign_in_url,
  })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn set_encrypt_secret_handler(
  manager: AFPluginState<Weak<UserManager>>,
  data: AFPluginData<UserSecretPB>,
  store_preferences: AFPluginState<Weak<KVStorePreferences>>,
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
) -> DataResult<UserEncryptionConfigurationPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let uid = manager.get_session()?.user_id;
  let profile = manager.get_user_profile_from_disk(uid).await?;

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

  data_result_ok(UserEncryptionConfigurationPB {
    require_secret: is_need_secret,
  })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn set_cloud_config_handler(
  manager: AFPluginState<Weak<UserManager>>,
  data: AFPluginData<UpdateCloudConfigPB>,
  store_preferences: AFPluginState<Weak<KVStorePreferences>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let session = manager.get_session()?;
  let update = data.into_inner();
  let store_preferences = upgrade_store_preferences(store_preferences)?;
  let mut config = get_cloud_config(session.user_id, &store_preferences)
    .ok_or(FlowyError::internal().with_context("Can't find any cloud config"))?;

  if let Some(enable_sync) = update.enable_sync {
    manager
      .cloud_services
      .set_enable_sync(session.user_id, enable_sync);
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

      let params =
        UpdateUserProfileParams::new(session.user_id).with_encryption_type(encryption_type);
      manager.update_user_profile(params).await?;
    }
  }

  save_cloud_config(session.user_id, &store_preferences, config.clone())?;

  let payload = CloudSettingPB {
    enable_sync: config.enable_sync,
    enable_encrypt: config.enable_encrypt,
    encrypt_secret: config.encrypt_secret,
    server_url: manager.cloud_services.service_url(),
  };

  send_notification(
    // Don't change this key. it's also used in the frontend
    "user_cloud_config",
    UserNotification::DidUpdateCloudConfig,
  )
  .payload(payload)
  .send();
  Ok(())
}

#[tracing::instrument(level = "info", skip_all, err)]
pub async fn get_cloud_config_handler(
  manager: AFPluginState<Weak<UserManager>>,
  store_preferences: AFPluginState<Weak<KVStorePreferences>>,
) -> DataResult<CloudSettingPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let session = manager.get_session()?;
  let store_preferences = upgrade_store_preferences(store_preferences)?;
  // Generate the default config if the config is not exist
  let config = get_or_create_cloud_config(session.user_id, &store_preferences);
  data_result_ok(CloudSettingPB {
    enable_sync: config.enable_sync,
    enable_encrypt: config.enable_encrypt,
    encrypt_secret: config.encrypt_secret,
    server_url: manager.cloud_services.service_url(),
  })
}

#[tracing::instrument(level = "debug", skip(manager), err)]
pub async fn get_all_workspace_handler(
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<RepeatedUserWorkspacePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let uid = manager.get_session()?.user_id;
  let user_workspaces = manager.get_all_user_workspaces(uid).await?;
  data_result_ok(user_workspaces.into())
}

#[tracing::instrument(level = "info", skip(data, manager), err)]
pub async fn open_workspace_handler(
  data: AFPluginData<UserWorkspaceIdPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.try_into_inner()?;
  manager.open_workspace(&params.workspace_id).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub async fn update_network_state_handler(
  data: AFPluginData<NetworkStatePB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let reachable = data.into_inner().ty.is_reachable();
  manager.cloud_services.set_network_reachable(reachable);
  manager
    .user_status_callback
    .read()
    .await
    .did_update_network(reachable);
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all)]
pub async fn get_anon_user_handler(
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let user_profile = manager.get_anon_user().await?;
  data_result_ok(user_profile)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn open_anon_user_handler(
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  manager.open_anon_user().await?;
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

  trace!("number of reminders: {}", reminders.len());
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
      ErrorCode::WorkspaceInitializeError,
      "The workspace id is empty",
    ));
  }
  let _session = manager.get_session()?;
  manager.reset_workspace(reset_pb).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn remove_reminder_event_handler(
  data: AFPluginData<ReminderIdentifierPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;

  let params = data.into_inner();
  let _ = manager.remove_reminder(params.id.as_str()).await;

  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn update_reminder_event_handler(
  data: AFPluginData<ReminderPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.into_inner();
  manager.update_reminder(params).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn add_workspace_member_handler(
  data: AFPluginData<AddWorkspaceMemberPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let data = data.try_into_inner()?;
  let manager = upgrade_manager(manager)?;
  manager
    .add_workspace_member(data.email, data.workspace_id)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn delete_workspace_member_handler(
  data: AFPluginData<RemoveWorkspaceMemberPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let data = data.try_into_inner()?;
  let manager = upgrade_manager(manager)?;
  manager
    .remove_workspace_member(data.email, data.workspace_id)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn get_workspace_members_handler(
  data: AFPluginData<QueryWorkspacePB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<RepeatedWorkspaceMemberPB, FlowyError> {
  let data = data.try_into_inner()?;
  let manager = upgrade_manager(manager)?;
  let members = manager
    .get_workspace_members(data.workspace_id)
    .await?
    .into_iter()
    .map(WorkspaceMemberPB::from)
    .collect();
  data_result_ok(RepeatedWorkspaceMemberPB { items: members })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn update_workspace_member_handler(
  data: AFPluginData<UpdateWorkspaceMemberPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let data = data.try_into_inner()?;
  let manager = upgrade_manager(manager)?;
  manager
    .update_workspace_member(data.email, data.workspace_id, data.role.into())
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn create_workspace_handler(
  data: AFPluginData<CreateWorkspacePB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<UserWorkspacePB, FlowyError> {
  let data = data.try_into_inner()?;
  let manager = upgrade_manager(manager)?;
  let new_workspace = manager.add_workspace(&data.name).await?;
  data_result_ok(new_workspace.into())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn delete_workspace_handler(
  delete_workspace_param: AFPluginData<UserWorkspaceIdPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let workspace_id = delete_workspace_param.try_into_inner()?.workspace_id;
  let manager = upgrade_manager(manager)?;
  manager.delete_workspace(&workspace_id).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn rename_workspace_handler(
  rename_workspace_param: AFPluginData<RenameWorkspacePB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let params = rename_workspace_param.try_into_inner()?;
  let manager = upgrade_manager(manager)?;
  manager
    .patch_workspace(&params.workspace_id, Some(&params.new_name), None)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn change_workspace_icon_handler(
  change_workspace_icon_param: AFPluginData<ChangeWorkspaceIconPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let params = change_workspace_icon_param.try_into_inner()?;
  let manager = upgrade_manager(manager)?;
  manager
    .patch_workspace(&params.workspace_id, None, Some(&params.new_icon))
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn invite_workspace_member_handler(
  param: AFPluginData<WorkspaceMemberInvitationPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let param = param.try_into_inner()?;
  let manager = upgrade_manager(manager)?;
  manager
    .invite_member_to_workspace(param.workspace_id, param.invitee_email, param.role.into())
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn list_workspace_invitations_handler(
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<RepeatedWorkspaceInvitationPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let invitations = manager.list_pending_workspace_invitations().await?;
  let invitations_pb: Vec<WorkspaceInvitationPB> = invitations
    .into_iter()
    .map(WorkspaceInvitationPB::from)
    .collect();
  data_result_ok(RepeatedWorkspaceInvitationPB {
    items: invitations_pb,
  })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn accept_workspace_invitations_handler(
  param: AFPluginData<AcceptWorkspaceInvitationPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let invite_id = param.try_into_inner()?.invite_id;
  let manager = upgrade_manager(manager)?;
  manager.accept_workspace_invitation(invite_id).await?;
  Ok(())
}

pub async fn leave_workspace_handler(
  param: AFPluginData<UserWorkspaceIdPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let workspace_id = param.into_inner().workspace_id;
  let manager = upgrade_manager(manager)?;
  manager.leave_workspace(&workspace_id).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn subscribe_workspace_handler(
  params: AFPluginData<SubscribeWorkspacePB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<PaymentLinkPB, FlowyError> {
  let params = params.try_into_inner()?;
  let manager = upgrade_manager(manager)?;
  let payment_link = manager.subscribe_workspace(params).await?;
  data_result_ok(PaymentLinkPB { payment_link })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn get_workspace_subscriptions_handler(
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<RepeatedWorkspaceSubscriptionPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let subs = manager
    .get_workspace_subscriptions()
    .await?
    .into_iter()
    .map(WorkspaceSubscriptionPB::from)
    .collect::<Vec<_>>();
  data_result_ok(RepeatedWorkspaceSubscriptionPB { items: subs })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn cancel_workspace_subscription_handler(
  param: AFPluginData<UserWorkspaceIdPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let workspace_id = param.into_inner().workspace_id;
  let manager = upgrade_manager(manager)?;
  manager.cancel_workspace_subscription(workspace_id).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn get_workspace_usage_handler(
  param: AFPluginData<UserWorkspaceIdPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<WorkspaceUsagePB, FlowyError> {
  let workspace_id = param.into_inner().workspace_id;
  let manager = upgrade_manager(manager)?;
  let workspace_usage = manager.get_workspace_usage(workspace_id).await?;
  data_result_ok(WorkspaceUsagePB {
    member_count: workspace_usage.member_count as u64,
    member_count_limit: workspace_usage.member_count_limit as u64,
    total_blob_bytes: workspace_usage.total_blob_bytes as u64,
    total_blob_bytes_limit: workspace_usage.total_blob_bytes_limit as u64,
  })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn get_billing_portal_handler(
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<BillingPortalPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let url = manager.get_billing_portal_url().await?;
  data_result_ok(BillingPortalPB { url })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn get_workspace_member_info(
  param: AFPluginData<WorkspaceMemberIdPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<WorkspaceMemberPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let member = manager.get_workspace_member_info(param.uid).await?;
  data_result_ok(member.into())
}
