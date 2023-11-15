use std::sync::{Arc, Weak};

use collab_database::database::WatchStream;
use collab_folder::FolderData;
use strum_macros::Display;

use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use flowy_error::FlowyResult;
use flowy_user_deps::cloud::{UserCloudConfig, UserCloudService};
use flowy_user_deps::entities::*;
use lib_dispatch::prelude::*;
use lib_infra::future::{to_fut, Fut};

use crate::errors::FlowyError;
use crate::event_handler::*;
use crate::manager::UserManager;

#[rustfmt::skip]
pub fn init(user_session: Weak<UserManager>) -> AFPlugin {
  let store_preferences = user_session
    .upgrade()
    .map(|session| session.get_store_preferences())
    .unwrap();
  AFPlugin::new()
    .name("Flowy-User")
    .state(user_session)
    .state(store_preferences)
    .event(UserEvent::SignIn, sign_in)
    .event(UserEvent::SignUp, sign_up)
    .event(UserEvent::InitUser, init_user_handler)
    .event(UserEvent::GetUserProfile, get_user_profile_handler)
    .event(UserEvent::SignOut, sign_out_handler)
    .event(UserEvent::UpdateUserProfile, update_user_profile_handler)
    .event(UserEvent::SetAppearanceSetting, set_appearance_setting)
    .event(UserEvent::GetAppearanceSetting, get_appearance_setting)
    .event(UserEvent::GetUserSetting, get_user_setting)
    .event(UserEvent::SetCloudConfig, set_cloud_config_handler)
    .event(UserEvent::GetCloudConfig, get_cloud_config_handler)
    .event(UserEvent::SetEncryptionSecret, set_encrypt_secret_handler)
    .event(UserEvent::CheckEncryptionSign, check_encrypt_secret_handler)
    .event(UserEvent::OauthSignIn, oauth_handler)
    .event(UserEvent::GetSignInURL, get_sign_in_url_handler)
    .event(UserEvent::GetOauthURLWithProvider, sign_in_with_provider_handler)
    .event(UserEvent::GetAllWorkspace, get_all_workspace_handler)
    .event(UserEvent::OpenWorkspace, open_workspace_handler)
    .event(UserEvent::UpdateNetworkState, update_network_state_handler)
    .event(UserEvent::GetHistoricalUsers, get_historical_users_handler)
    .event(UserEvent::OpenHistoricalUser, open_historical_users_handler)
    .event(UserEvent::PushRealtimeEvent, push_realtime_event_handler)
    .event(UserEvent::CreateReminder, create_reminder_event_handler)
    .event(UserEvent::GetAllReminders, get_all_reminder_event_handler)
    .event(UserEvent::RemoveReminder, remove_reminder_event_handler)
    .event(UserEvent::UpdateReminder, update_reminder_event_handler)
    .event(UserEvent::ResetWorkspace, reset_workspace_handler)
    .event(UserEvent::SetDateTimeSettings, set_date_time_settings)
    .event(UserEvent::GetDateTimeSettings, get_date_time_settings)
    .event(UserEvent::SetNotificationSettings, set_notification_settings)
    .event(UserEvent::GetNotificationSettings, get_notification_settings) 
      // Workspace member
    .event(UserEvent::AddWorkspaceMember, add_workspace_member_handler)
    .event(UserEvent::RemoveWorkspaceMember, delete_workspace_member_handler)
    .event(UserEvent::GetWorkspaceMember, get_workspace_member_handler)
    .event(UserEvent::UpdateWorkspaceMember, update_workspace_member_handler)
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum UserEvent {
  /// Only use when the [Authenticator] is Local or SelfHosted
  /// Logging into an account using a register email and password
  #[event(input = "SignInPayloadPB", output = "UserProfilePB")]
  SignIn = 0,

  /// Only use when the [Authenticator] is Local or SelfHosted
  /// Creating a new account
  #[event(input = "SignUpPayloadPB", output = "UserProfilePB")]
  SignUp = 1,

  /// Logging out fo an account
  #[event()]
  SignOut = 2,

  /// Update the user information
  #[event(input = "UpdateUserProfilePayloadPB")]
  UpdateUserProfile = 3,

  /// Get the user information
  #[event(output = "UserProfilePB")]
  GetUserProfile = 4,

  /// Initialize resources for the current user after launching the application
  ///
  #[event()]
  InitUser = 6,

  /// Change the visual elements of the interface, such as theme, font and more
  #[event(input = "AppearanceSettingsPB")]
  SetAppearanceSetting = 7,

  /// Get the appearance setting
  #[event(output = "AppearanceSettingsPB")]
  GetAppearanceSetting = 8,

  /// Get the settings of the user, such as the user storage folder
  #[event(output = "UserSettingPB")]
  GetUserSetting = 9,

  #[event(input = "OauthSignInPB", output = "UserProfilePB")]
  OauthSignIn = 10,

  /// Get the OAuth callback url
  /// Only use when the [Authenticator] is AFCloud
  #[event(input = "SignInUrlPayloadPB", output = "SignInUrlPB")]
  GetSignInURL = 11,

  #[event(input = "OauthProviderPB", output = "OauthProviderDataPB")]
  GetOauthURLWithProvider = 12,

  #[event(input = "UpdateCloudConfigPB")]
  SetCloudConfig = 13,

  #[event(output = "UserCloudConfigPB")]
  GetCloudConfig = 14,

  #[event(input = "UserSecretPB")]
  SetEncryptionSecret = 15,

  #[event(output = "UserEncryptionConfigurationPB")]
  CheckEncryptionSign = 16,

  /// Return the all the workspaces of the user
  #[event(output = "RepeatedUserWorkspacePB")]
  GetAllWorkspace = 17,

  #[event(input = "UserWorkspaceIdPB")]
  OpenWorkspace = 21,

  #[event(input = "NetworkStatePB")]
  UpdateNetworkState = 24,

  #[event(output = "RepeatedHistoricalUserPB")]
  GetHistoricalUsers = 25,

  #[event(input = "HistoricalUserPB")]
  OpenHistoricalUser = 26,

  /// Push a realtime event to the user. Currently, the realtime event
  /// is only used when the auth type is: [Authenticator::Supabase].
  ///
  #[event(input = "RealtimePayloadPB")]
  PushRealtimeEvent = 27,

  #[event(input = "ReminderPB")]
  CreateReminder = 28,

  #[event(output = "RepeatedReminderPB")]
  GetAllReminders = 29,

  #[event(input = "ReminderIdentifierPB")]
  RemoveReminder = 30,

  #[event(input = "ReminderPB")]
  UpdateReminder = 31,

  #[event(input = "ResetWorkspacePB")]
  ResetWorkspace = 32,

  /// Change the Date/Time formats globally
  #[event(input = "DateTimeSettingsPB")]
  SetDateTimeSettings = 33,

  /// Retrieve the Date/Time formats
  #[event(output = "DateTimeSettingsPB")]
  GetDateTimeSettings = 34,

  #[event(input = "NotificationSettingsPB")]
  SetNotificationSettings = 35,

  #[event(output = "NotificationSettingsPB")]
  GetNotificationSettings = 36,

  #[event(output = "AddWorkspaceMemberPB")]
  AddWorkspaceMember = 37,

  #[event(output = "RemoveWorkspaceMemberPB")]
  RemoveWorkspaceMember = 38,

  #[event(output = "UpdateWorkspaceMemberPB")]
  UpdateWorkspaceMember = 39,

  #[event(output = "QueryWorkspacePB")]
  GetWorkspaceMember = 40,
}

pub struct SignUpContext {
  /// Indicate whether the user is new or not.
  pub is_new: bool,
  /// If the user is sign in as guest, and the is_new is true, then the folder data will be not
  /// None.
  pub local_folder: Option<FolderData>,
}

pub trait UserStatusCallback: Send + Sync + 'static {
  /// When the [Authenticator] changed, this method will be called. Currently, the auth type
  /// will be changed when the user sign in or sign up.
  fn authenticator_did_changed(&self, _authenticator: Authenticator) {}
  /// This will be called after the application launches if the user is already signed in.
  /// If the user is not signed in, this method will not be called
  fn did_init(
    &self,
    user_id: i64,
    cloud_config: &Option<UserCloudConfig>,
    user_workspace: &UserWorkspace,
    device_id: &str,
  ) -> Fut<FlowyResult<()>>;
  /// Will be called after the user signed in.
  fn did_sign_in(
    &self,
    user_id: i64,
    user_workspace: &UserWorkspace,
    device_id: &str,
  ) -> Fut<FlowyResult<()>>;
  /// Will be called after the user signed up.
  fn did_sign_up(
    &self,
    is_new_user: bool,
    user_profile: &UserProfile,
    user_workspace: &UserWorkspace,
    device_id: &str,
  ) -> Fut<FlowyResult<()>>;

  fn did_expired(&self, token: &str, user_id: i64) -> Fut<FlowyResult<()>>;
  fn open_workspace(&self, user_id: i64, user_workspace: &UserWorkspace) -> Fut<FlowyResult<()>>;
  fn did_update_network(&self, _reachable: bool) {}
}

/// The user cloud service provider.
/// The provider can be supabase, firebase, aws, or any other cloud service.
pub trait UserCloudServiceProvider: Send + Sync + 'static {
  fn set_token(&self, token: &str) -> Result<(), FlowyError>;
  fn subscribe_token_state(&self) -> Option<WatchStream<UserTokenState>> {
    None
  }

  fn set_enable_sync(&self, uid: i64, enable_sync: bool);
  fn set_encrypt_secret(&self, secret: String);
  fn set_authenticator(&self, authenticator: Authenticator);
  fn get_authenticator(&self) -> Authenticator;
  fn set_device_id(&self, device_id: &str);
  fn get_user_service(&self) -> Result<Arc<dyn UserCloudService>, FlowyError>;
  fn service_name(&self) -> String;
}

impl<T> UserCloudServiceProvider for Arc<T>
where
  T: UserCloudServiceProvider,
{
  fn set_token(&self, token: &str) -> Result<(), FlowyError> {
    (**self).set_token(token)
  }

  fn set_enable_sync(&self, uid: i64, enable_sync: bool) {
    (**self).set_enable_sync(uid, enable_sync)
  }

  fn set_encrypt_secret(&self, secret: String) {
    (**self).set_encrypt_secret(secret)
  }

  fn set_authenticator(&self, authenticator: Authenticator) {
    (**self).set_authenticator(authenticator)
  }

  fn get_authenticator(&self) -> Authenticator {
    (**self).get_authenticator()
  }

  fn set_device_id(&self, device_id: &str) {
    (**self).set_device_id(device_id)
  }

  fn get_user_service(&self) -> Result<Arc<dyn UserCloudService>, FlowyError> {
    (**self).get_user_service()
  }

  fn service_name(&self) -> String {
    (**self).service_name()
  }
}

/// Acts as a placeholder [UserStatusCallback] for the user session, but does not perform any function
pub(crate) struct DefaultUserStatusCallback;
impl UserStatusCallback for DefaultUserStatusCallback {
  fn did_init(
    &self,
    _user_id: i64,
    _cloud_config: &Option<UserCloudConfig>,
    _user_workspace: &UserWorkspace,
    _device_id: &str,
  ) -> Fut<FlowyResult<()>> {
    to_fut(async { Ok(()) })
  }

  fn did_sign_in(
    &self,
    _user_id: i64,
    _user_workspace: &UserWorkspace,
    _device_id: &str,
  ) -> Fut<FlowyResult<()>> {
    to_fut(async { Ok(()) })
  }

  fn did_sign_up(
    &self,
    _is_new_user: bool,
    _user_profile: &UserProfile,
    _user_workspace: &UserWorkspace,
    _device_id: &str,
  ) -> Fut<FlowyResult<()>> {
    to_fut(async { Ok(()) })
  }

  fn did_expired(&self, _token: &str, _user_id: i64) -> Fut<FlowyResult<()>> {
    to_fut(async { Ok(()) })
  }

  fn open_workspace(&self, _user_id: i64, _user_workspace: &UserWorkspace) -> Fut<FlowyResult<()>> {
    to_fut(async { Ok(()) })
  }
}
