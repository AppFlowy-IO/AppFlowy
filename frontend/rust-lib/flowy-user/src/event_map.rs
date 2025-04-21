use client_api::entity::billing_dto::SubscriptionPlan;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use flowy_error::FlowyResult;
use flowy_user_pub::cloud::UserCloudConfig;
use flowy_user_pub::entities::*;
use lib_dispatch::prelude::*;
use lib_infra::async_trait::async_trait;
use std::sync::Weak;
use strum_macros::Display;
use uuid::Uuid;

use crate::event_handler::*;
use crate::user_manager::UserManager;

#[rustfmt::skip]
pub fn init(user_manager: Weak<UserManager>) -> AFPlugin {
  let store_preferences = user_manager
    .upgrade()
    .map(|session| session.get_store_preferences())
    .unwrap();
  AFPlugin::new()
    .name("Flowy-User")
    .state(user_manager)
    .state(store_preferences)
    .event(UserEvent::SignInWithEmailPassword, sign_in_with_email_password_handler)
    .event(UserEvent::MagicLinkSignIn, sign_in_with_magic_link_handler)
    .event(UserEvent::SignUp, sign_up)
    .event(UserEvent::InitUser, init_user_handler)
    .event(UserEvent::GetUserProfile, get_user_profile_handler)
    .event(UserEvent::SignOut, sign_out_handler)
    .event(UserEvent::DeleteAccount, delete_account_handler)
    .event(UserEvent::UpdateUserProfile, update_user_profile_handler)
    .event(UserEvent::SetAppearanceSetting, set_appearance_setting)
    .event(UserEvent::GetAppearanceSetting, get_appearance_setting)
    .event(UserEvent::GetUserSetting, get_user_setting)
    .event(UserEvent::SetCloudConfig, set_cloud_config_handler)
    .event(UserEvent::GetCloudConfig, get_cloud_config_handler)
    .event(UserEvent::OauthSignIn, oauth_sign_in_handler)
    .event(UserEvent::GenerateSignInURL, gen_sign_in_url_handler)
    .event(UserEvent::GetOauthURLWithProvider, sign_in_with_provider_handler)
    .event(UserEvent::OpenWorkspace, open_workspace_handler)
    .event(UserEvent::GetUserWorkspace, get_user_workspace_handler)
    .event(UserEvent::UpdateNetworkState, update_network_state_handler)
    .event(UserEvent::OpenAnonUser, open_anon_user_handler)
    .event(UserEvent::GetAnonUser, get_anon_user_handler)
    .event(UserEvent::PushRealtimeEvent, push_realtime_event_handler)
    .event(UserEvent::CreateReminder, create_reminder_event_handler)
    .event(UserEvent::GetAllReminders, get_all_reminder_event_handler)
    .event(UserEvent::RemoveReminder, remove_reminder_event_handler)
    .event(UserEvent::UpdateReminder, update_reminder_event_handler)
    .event(UserEvent::SetDateTimeSettings, set_date_time_settings)
    .event(UserEvent::GetDateTimeSettings, get_date_time_settings)
    .event(UserEvent::SetNotificationSettings, set_notification_settings)
    .event(UserEvent::GetNotificationSettings, get_notification_settings)
    .event(UserEvent::ImportAppFlowyDataFolder, import_appflowy_data_folder_handler)
    .event(UserEvent::GetMemberInfo, get_workspace_member_info)
    .event(UserEvent::RemoveWorkspaceMember, delete_workspace_member_handler)
    .event(UserEvent::GetWorkspaceMembers, get_workspace_members_handler)
    .event(UserEvent::UpdateWorkspaceMember, update_workspace_member_handler)
      // Workspace
    .event(UserEvent::GetAllWorkspace, get_all_workspace_handler)
    .event(UserEvent::CreateWorkspace, create_workspace_handler)
    .event(UserEvent::DeleteWorkspace, delete_workspace_handler)
    .event(UserEvent::RenameWorkspace, rename_workspace_handler)
    .event(UserEvent::ChangeWorkspaceIcon, change_workspace_icon_handler)
    .event(UserEvent::LeaveWorkspace, leave_workspace_handler)
    .event(UserEvent::InviteWorkspaceMember, invite_workspace_member_handler)
    .event(UserEvent::ListWorkspaceInvitations, list_workspace_invitations_handler)
    .event(UserEvent::AcceptWorkspaceInvitation, accept_workspace_invitations_handler)
    // Billing
    .event(UserEvent::SubscribeWorkspace, subscribe_workspace_handler)
    .event(UserEvent::GetWorkspaceSubscriptionInfo, get_workspace_subscription_info_handler)
    .event(UserEvent::CancelWorkspaceSubscription, cancel_workspace_subscription_handler)
    .event(UserEvent::GetWorkspaceUsage, get_workspace_usage_handler)
    .event(UserEvent::GetBillingPortal, get_billing_portal_handler)
    .event(UserEvent::UpdateWorkspaceSubscriptionPaymentPeriod, update_workspace_subscription_payment_period_handler)
    .event(UserEvent::GetSubscriptionPlanDetails, get_subscription_plan_details_handler)
    // Workspace Setting
    .event(UserEvent::UpdateWorkspaceSetting, update_workspace_setting_handler)
    .event(UserEvent::GetWorkspaceSetting, get_workspace_setting_handler)
    .event(UserEvent::NotifyDidSwitchPlan, notify_did_switch_plan_handler)
    .event(UserEvent::PasscodeSignIn, sign_in_with_passcode_handler)
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum UserEvent {
  /// Only use when the [AuthType] is Local or SelfHosted
  /// Logging into an account using a register email and password
  #[event(input = "SignInPayloadPB", output = "GotrueTokenResponsePB")]
  SignInWithEmailPassword = 0,

  /// Only use when the [AuthType] is Local or SelfHosted
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
  /// Only use when the [AuthType] is AFCloud
  #[event(input = "SignInUrlPayloadPB", output = "SignInUrlPB")]
  GenerateSignInURL = 11,

  #[event(input = "OauthProviderPB", output = "OauthProviderDataPB")]
  GetOauthURLWithProvider = 12,

  #[event(input = "UpdateCloudConfigPB")]
  SetCloudConfig = 13,

  #[event(output = "CloudSettingPB")]
  GetCloudConfig = 14,

  /// Return the all the workspaces of the user
  #[event(output = "RepeatedUserWorkspacePB")]
  GetAllWorkspace = 17,

  #[event(input = "OpenUserWorkspacePB")]
  OpenWorkspace = 21,

  #[event(input = "UserWorkspaceIdPB", output = "UserWorkspacePB")]
  GetUserWorkspace = 22,

  #[event(input = "NetworkStatePB")]
  UpdateNetworkState = 24,

  #[event(output = "UserProfilePB")]
  GetAnonUser = 25,

  #[event()]
  OpenAnonUser = 26,

  /// Push a realtime event to the user. Currently, the realtime event
  /// is only used when the auth type is: [AuthType::Supabase].
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

  // Deprecated
  #[event(input = "AddWorkspaceMemberPB")]
  AddWorkspaceMember = 37,

  #[event(input = "RemoveWorkspaceMemberPB")]
  RemoveWorkspaceMember = 38,

  #[event(input = "UpdateWorkspaceMemberPB")]
  UpdateWorkspaceMember = 39,

  #[event(input = "QueryWorkspacePB", output = "RepeatedWorkspaceMemberPB")]
  GetWorkspaceMembers = 40,

  #[event(input = "ImportAppFlowyDataPB")]
  ImportAppFlowyDataFolder = 41,

  #[event(input = "CreateWorkspacePB", output = "UserWorkspacePB")]
  CreateWorkspace = 42,

  #[event(input = "UserWorkspaceIdPB")]
  DeleteWorkspace = 43,

  #[event(input = "RenameWorkspacePB")]
  RenameWorkspace = 44,

  #[event(input = "ChangeWorkspaceIconPB")]
  ChangeWorkspaceIcon = 45,

  #[event(input = "UserWorkspaceIdPB")]
  LeaveWorkspace = 46,

  #[event(input = "WorkspaceMemberInvitationPB")]
  InviteWorkspaceMember = 47,

  #[event(output = "RepeatedWorkspaceInvitationPB")]
  ListWorkspaceInvitations = 48,

  #[event(input = "AcceptWorkspaceInvitationPB")]
  AcceptWorkspaceInvitation = 49,

  #[event(input = "MagicLinkSignInPB", output = "UserProfilePB")]
  MagicLinkSignIn = 50,

  #[event(input = "SubscribeWorkspacePB", output = "PaymentLinkPB")]
  SubscribeWorkspace = 51,

  #[event(input = "CancelWorkspaceSubscriptionPB")]
  CancelWorkspaceSubscription = 53,

  #[event(input = "UserWorkspaceIdPB", output = "WorkspaceUsagePB")]
  GetWorkspaceUsage = 54,

  #[event(output = "BillingPortalPB")]
  GetBillingPortal = 55,

  #[event(input = "WorkspaceMemberIdPB", output = "WorkspaceMemberPB")]
  GetMemberInfo = 56,

  #[event(input = "UpdateUserWorkspaceSettingPB")]
  UpdateWorkspaceSetting = 57,

  #[event(input = "UserWorkspaceIdPB", output = "WorkspaceSettingsPB")]
  GetWorkspaceSetting = 58,

  #[event(input = "UserWorkspaceIdPB", output = "WorkspaceSubscriptionInfoPB")]
  GetWorkspaceSubscriptionInfo = 59,

  #[event(input = "UpdateWorkspaceSubscriptionPaymentPeriodPB")]
  UpdateWorkspaceSubscriptionPaymentPeriod = 61,

  #[event(output = "RepeatedSubscriptionPlanDetailPB")]
  GetSubscriptionPlanDetails = 62,

  #[event(input = "SuccessWorkspaceSubscriptionPB")]
  NotifyDidSwitchPlan = 63,

  #[event()]
  DeleteAccount = 64,

  #[event(input = "PasscodeSignInPB", output = "GotrueTokenResponsePB")]
  PasscodeSignIn = 65,
}

#[async_trait]
pub trait UserStatusCallback: Send + Sync + 'static {
  /// When the [AuthType] changed, this method will be called. Currently, the auth type
  /// will be changed when the user sign in or sign up.
  fn on_auth_type_changed(&self, _authenticator: AuthType) {}
  /// Fires on app launch, but only if the user is already signed in.
  async fn on_launch_if_authenticated(
    &self,
    _user_id: i64,
    _cloud_config: &Option<UserCloudConfig>,
    _user_workspace: &UserWorkspace,
    _device_id: &str,
    _auth_type: &AuthType,
  ) -> FlowyResult<()> {
    Ok(())
  }
  /// Fires right after the user successfully signs in.
  async fn on_sign_in(
    &self,
    _user_id: i64,
    _user_workspace: &UserWorkspace,
    _device_id: &str,
    _auth_type: &AuthType,
  ) -> FlowyResult<()> {
    Ok(())
  }

  /// Fires right after the user successfully signs up.
  async fn on_sign_up(
    &self,
    _is_new_user: bool,
    _user_profile: &UserProfile,
    _user_workspace: &UserWorkspace,
    _device_id: &str,
    _auth_type: &AuthType,
  ) -> FlowyResult<()> {
    Ok(())
  }

  /// Fires when an authentication token has expired.
  async fn on_token_expired(&self, _token: &str, _user_id: i64) -> FlowyResult<()> {
    Ok(())
  }

  /// Fires when a workspace is opened by the user.
  async fn on_workspace_opened(
    &self,
    _user_id: i64,
    _workspace_id: &Uuid,
    _user_workspace: &UserWorkspace,
    _auth_type: &AuthType,
  ) -> FlowyResult<()> {
    Ok(())
  }
  fn on_network_status_changed(&self, _reachable: bool) {}
  fn on_subscription_plans_updated(&self, _plans: Vec<SubscriptionPlan>) {}
  fn on_storage_permission_updated(&self, _can_write: bool) {}
}

/// Acts as a placeholder [UserStatusCallback] for the user session, but does not perform any function
pub(crate) struct DefaultUserStatusCallback;
impl UserStatusCallback for DefaultUserStatusCallback {}
