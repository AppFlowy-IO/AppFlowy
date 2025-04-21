use crate::entities::*;
use crate::notification::{send_notification, UserNotification};
use crate::services::cloud_config::{
  get_cloud_config, get_or_create_cloud_config, save_cloud_config,
};
use crate::services::data_import::prepare_import;
use crate::user_manager::UserManager;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_sqlite::kv::KVStorePreferences;
use flowy_user_pub::entities::*;
use flowy_user_pub::sql::UserWorkspaceChangeset;
use lib_dispatch::prelude::*;
use lib_infra::box_any::BoxAny;
use serde_json::Value;
use std::str::FromStr;
use std::sync::Weak;
use std::{convert::TryInto, sync::Arc};
use tracing::{event, trace};
use uuid::Uuid;

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

#[tracing::instrument(level = "debug", name = "sign_in", skip(data, manager), fields(
    email = % data.email
), err)]
pub async fn sign_in_with_email_password_handler(
  data: AFPluginData<SignInPayloadPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<GotrueTokenResponsePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: SignInParams = data.into_inner().try_into()?;

  match manager
    .sign_in_with_password(&params.email, &params.password)
    .await
  {
    Ok(token) => data_result_ok(token.into()),
    Err(err) => Err(err),
  }
}

#[tracing::instrument(
    level = "debug",
    name = "sign_up",
    skip(data, manager),
    fields(
        email = % data.email,
        name = % data.name,
    ),
    err
)]
pub async fn sign_up(
  data: AFPluginData<SignUpPayloadPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: SignUpParams = data.into_inner().try_into()?;
  let auth_type = params.auth_type;

  match manager.sign_up(auth_type, BoxAny::new(params)).await {
    Ok(profile) => data_result_ok(UserProfilePB::from(profile)),
    Err(err) => Err(err),
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
  tokio::spawn(async move {
    if let Some(manager) = weak_manager.upgrade() {
      let _ = manager.refresh_user_profile(&cloned_user_profile).await;
    }
  });

  // When the user is logged in with a local account, the email field is a placeholder and should
  // not be exposed to the client. So we set the email field to an empty string.
  if user_profile.auth_type == AuthType::Local {
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

#[tracing::instrument(level = "debug", skip(manager))]
pub async fn delete_account_handler(
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  manager.delete_account().await?;
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
  store_preferences.set_object(APPEARANCE_SETTING_CACHE_KEY, &setting)?;
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

  store_preferences.set_object(DATE_TIME_SETTINGS_CACHE_KEY, &setting)?;
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
  store_preferences.set_object(NOTIFICATION_SETTINGS_CACHE_KEY, &setting)?;
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
  tokio::spawn(async move {
    let result = async {
      let manager = upgrade_manager(manager)?;
      let imported_folder = prepare_import(
        &data.path,
        data.parent_view_id,
        &manager.authenticate_user.user_config.app_version,
      )
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
pub async fn sign_in_with_passcode_handler(
  data: AFPluginData<PasscodeSignInPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<GotrueTokenResponsePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.into_inner();
  let response = manager
    .sign_in_with_passcode(&params.email, &params.passcode)
    .await?;
  data_result_ok(response.into())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub async fn oauth_sign_in_handler(
  data: AFPluginData<OauthSignInPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.into_inner();
  let authenticator: AuthType = params.authenticator.into();
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
  let authenticator: AuthType = params.authenticator.into();
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
      .cloud_service
      .set_enable_sync(session.user_id, enable_sync);
    config.enable_sync = enable_sync;
  }

  save_cloud_config(session.user_id, &store_preferences, &config)?;

  let payload = CloudSettingPB {
    enable_sync: config.enable_sync,
    enable_encrypt: config.enable_encrypt,
    encrypt_secret: config.encrypt_secret,
    server_url: manager.cloud_service.service_url(),
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
    server_url: manager.cloud_service.service_url(),
  })
}

#[tracing::instrument(level = "debug", skip(manager), err)]
pub async fn get_all_workspace_handler(
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<RepeatedUserWorkspacePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let profile = manager.get_user_profile().await?;
  let user_workspaces = manager
    .get_all_user_workspaces(profile.uid, profile.auth_type)
    .await?;

  data_result_ok(RepeatedUserWorkspacePB::from((
    profile.auth_type,
    user_workspaces,
  )))
}

#[tracing::instrument(level = "info", skip(data, manager), err)]
pub async fn open_workspace_handler(
  data: AFPluginData<OpenUserWorkspacePB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.try_into_inner()?;
  let workspace_id = Uuid::from_str(&params.workspace_id)?;
  manager
    .open_workspace(&workspace_id, AuthType::from(params.auth_type))
    .await?;
  Ok(())
}

#[tracing::instrument(level = "info", skip(data, manager), err)]
pub async fn get_user_workspace_handler(
  data: AFPluginData<UserWorkspaceIdPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<UserWorkspacePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.try_into_inner()?;
  let workspace_id = Uuid::from_str(&params.workspace_id)?;
  let uid = manager.user_id()?;
  let user_workspace = manager.get_user_workspace_from_db(uid, &workspace_id)?;
  data_result_ok(UserWorkspacePB::from(user_workspace))
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub async fn update_network_state_handler(
  data: AFPluginData<NetworkStatePB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let reachable = data.into_inner().ty.is_reachable();
  manager.cloud_service.set_network_reachable(reachable);
  manager
    .user_status_callback
    .read()
    .await
    .on_network_status_changed(reachable);
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
pub async fn delete_workspace_member_handler(
  data: AFPluginData<RemoveWorkspaceMemberPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let data = data.try_into_inner()?;
  let manager = upgrade_manager(manager)?;
  let workspace_id = Uuid::from_str(&data.workspace_id)?;
  manager
    .remove_workspace_member(data.email, workspace_id)
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
  let workspace_id = Uuid::from_str(&data.workspace_id)?;
  let members = manager
    .get_workspace_members(workspace_id)
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
  let workspace_id = Uuid::from_str(&data.workspace_id)?;
  manager
    .update_workspace_member(data.email, workspace_id, data.role.into())
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn create_workspace_handler(
  data: AFPluginData<CreateWorkspacePB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<UserWorkspacePB, FlowyError> {
  let data = data.try_into_inner()?;
  let auth_type = AuthType::from(data.auth_type);
  let manager = upgrade_manager(manager)?;
  let new_workspace = manager.create_workspace(&data.name, auth_type).await?;
  data_result_ok(UserWorkspacePB::from((auth_type, new_workspace)))
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn delete_workspace_handler(
  delete_workspace_param: AFPluginData<UserWorkspaceIdPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let workspace_id = delete_workspace_param.try_into_inner()?.workspace_id;
  let manager = upgrade_manager(manager)?;
  let workspace_id = Uuid::from_str(&workspace_id)?;
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
  let workspace_id = Uuid::from_str(&params.workspace_id)?;
  let changeset = UserWorkspaceChangeset {
    id: params.workspace_id,
    name: Some(params.new_name),
    icon: None,
  };
  manager.patch_workspace(&workspace_id, changeset).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn change_workspace_icon_handler(
  change_workspace_icon_param: AFPluginData<ChangeWorkspaceIconPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let params = change_workspace_icon_param.try_into_inner()?;
  let manager = upgrade_manager(manager)?;
  let workspace_id = Uuid::from_str(&params.workspace_id)?;
  let changeset = UserWorkspaceChangeset {
    id: workspace_id.to_string(),
    name: None,
    icon: Some(params.new_icon),
  };
  manager.patch_workspace(&workspace_id, changeset).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn invite_workspace_member_handler(
  param: AFPluginData<WorkspaceMemberInvitationPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let param = param.try_into_inner()?;
  let manager = upgrade_manager(manager)?;
  let workspace_id = Uuid::from_str(&param.workspace_id)?;
  manager
    .invite_member_to_workspace(workspace_id, param.invitee_email, param.role.into())
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
  let workspace_id = Uuid::from_str(&workspace_id)?;
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
pub async fn get_workspace_subscription_info_handler(
  params: AFPluginData<UserWorkspaceIdPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<WorkspaceSubscriptionInfoPB, FlowyError> {
  let params = params.try_into_inner()?;
  let manager = upgrade_manager(manager)?;
  let subs = manager
    .get_workspace_subscription_info(params.workspace_id)
    .await?;
  data_result_ok(subs)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn cancel_workspace_subscription_handler(
  param: AFPluginData<CancelWorkspaceSubscriptionPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let params = param.into_inner();
  let manager = upgrade_manager(manager)?;
  manager
    .cancel_workspace_subscription(params.workspace_id, params.plan.into(), Some(params.reason))
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn get_workspace_usage_handler(
  param: AFPluginData<UserWorkspaceIdPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<WorkspaceUsagePB, FlowyError> {
  let workspace_id = Uuid::from_str(&param.into_inner().workspace_id)?;
  let manager = upgrade_manager(manager)?;
  let workspace_usage = manager.get_workspace_usage(&workspace_id).await?;
  data_result_ok(WorkspaceUsagePB::from(workspace_usage))
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
pub async fn update_workspace_subscription_payment_period_handler(
  params: AFPluginData<UpdateWorkspaceSubscriptionPaymentPeriodPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> FlowyResult<()> {
  let workspace_id = Uuid::from_str(&params.workspace_id)?;
  let params = params.try_into_inner()?;
  let manager = upgrade_manager(manager)?;
  manager
    .update_workspace_subscription_payment_period(
      &workspace_id,
      params.plan.into(),
      params.recurring_interval.into(),
    )
    .await
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn get_subscription_plan_details_handler(
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<RepeatedSubscriptionPlanDetailPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let plans = manager
    .get_subscription_plan_details()
    .await?
    .into_iter()
    .map(SubscriptionPlanDetailPB::from)
    .collect::<Vec<_>>();
  data_result_ok(RepeatedSubscriptionPlanDetailPB { items: plans })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn get_workspace_member_info(
  param: AFPluginData<WorkspaceMemberIdPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<WorkspaceMemberPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let workspace_id = manager.get_session()?.user_workspace.workspace_id()?;
  let member = manager
    .get_workspace_member_info(param.uid, &workspace_id)
    .await?;
  data_result_ok(member.into())
}

#[tracing::instrument(level = "info", skip_all, err)]
pub async fn update_workspace_setting_handler(
  params: AFPluginData<UpdateUserWorkspaceSettingPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let params = params.try_into_inner()?;
  let manager = upgrade_manager(manager)?;
  manager.update_workspace_setting(params).await?;
  Ok(())
}

#[tracing::instrument(level = "info", skip_all, err)]
pub async fn get_workspace_setting_handler(
  params: AFPluginData<UserWorkspaceIdPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<WorkspaceSettingsPB, FlowyError> {
  let params = params.try_into_inner()?;
  let workspace_id = Uuid::from_str(&params.workspace_id)?;
  let manager = upgrade_manager(manager)?;
  let pb = manager.get_workspace_settings(&workspace_id).await?;
  data_result_ok(pb)
}

#[tracing::instrument(level = "info", skip_all, err)]
pub async fn notify_did_switch_plan_handler(
  params: AFPluginData<SuccessWorkspaceSubscriptionPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let success = params.into_inner();
  let manager = upgrade_manager(manager)?;
  manager.notify_did_switch_plan(success).await?;
  Ok(())
}
