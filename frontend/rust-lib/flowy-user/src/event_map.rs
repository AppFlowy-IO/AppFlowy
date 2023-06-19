use std::sync::Arc;

use strum_macros::Display;

use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use flowy_error::FlowyResult;

use lib_dispatch::prelude::*;
use lib_infra::box_any::BoxAny;
use lib_infra::future::{to_fut, Fut, FutureResult};

use crate::entities::{SignInResponse, SignUpResponse, UpdateUserProfileParams, UserProfile};
use crate::event_handler::*;
use crate::services::AuthType;
use crate::{errors::FlowyError, services::UserSession};

pub fn init(user_session: Arc<UserSession>) -> AFPlugin {
  AFPlugin::new()
    .name("Flowy-User")
    .state(user_session)
    .event(UserEvent::SignIn, sign_in)
    .event(UserEvent::SignUp, sign_up)
    .event(UserEvent::InitUser, init_user_handler)
    .event(UserEvent::GetUserProfile, get_user_profile_handler)
    .event(UserEvent::SignOut, sign_out)
    .event(UserEvent::UpdateUserProfile, update_user_profile_handler)
    .event(UserEvent::CheckUser, check_user_handler)
    .event(UserEvent::SetAppearanceSetting, set_appearance_setting)
    .event(UserEvent::GetAppearanceSetting, get_appearance_setting)
    .event(UserEvent::GetUserSetting, get_user_setting)
    .event(UserEvent::ThirdPartyAuth, third_party_auth_handler)
}

pub(crate) struct DefaultUserStatusCallback;
impl UserStatusCallback for DefaultUserStatusCallback {
  fn auth_type_did_changed(&self, _auth_type: AuthType) {}

  fn did_sign_in(&self, _user_id: i64, _workspace_id: &str) -> Fut<FlowyResult<()>> {
    to_fut(async { Ok(()) })
  }

  fn did_sign_up(&self, _user_profile: &UserProfile) -> Fut<FlowyResult<()>> {
    to_fut(async { Ok(()) })
  }

  fn did_expired(&self, _token: &str, _user_id: i64) -> Fut<FlowyResult<()>> {
    to_fut(async { Ok(()) })
  }
}

pub trait UserStatusCallback: Send + Sync + 'static {
  fn auth_type_did_changed(&self, auth_type: AuthType);
  fn did_sign_in(&self, user_id: i64, workspace_id: &str) -> Fut<FlowyResult<()>>;
  fn did_sign_up(&self, user_profile: &UserProfile) -> Fut<FlowyResult<()>>;
  fn did_expired(&self, token: &str, user_id: i64) -> Fut<FlowyResult<()>>;
}

/// The user cloud service provider.
/// The provider can be supabase, firebase, aws, or any other cloud service.
pub trait UserCloudServiceProvider: Send + Sync + 'static {
  fn set_auth_type(&self, auth_type: AuthType);
  fn get_auth_service(&self) -> Result<Arc<dyn UserAuthService>, FlowyError>;
}

impl<T> UserCloudServiceProvider for Arc<T>
where
  T: UserCloudServiceProvider,
{
  fn set_auth_type(&self, auth_type: AuthType) {
    (**self).set_auth_type(auth_type)
  }

  fn get_auth_service(&self) -> Result<Arc<dyn UserAuthService>, FlowyError> {
    (**self).get_auth_service()
  }
}

/// Provide the generic interface for the user cloud service
/// The user cloud service is responsible for the user authentication and user profile management
pub trait UserAuthService: Send + Sync {
  /// Sign up a new account.
  /// The type of the params is defined the this trait's implementation.
  /// Use the `unbox_or_error` of the [BoxAny] to get the params.
  fn sign_up(&self, params: BoxAny) -> FutureResult<SignUpResponse, FlowyError>;

  /// Sign in an account
  /// The type of the params is defined the this trait's implementation.
  fn sign_in(&self, params: BoxAny) -> FutureResult<SignInResponse, FlowyError>;

  /// Sign out an account
  fn sign_out(&self, token: Option<String>) -> FutureResult<(), FlowyError>;

  /// Using the user's token to update the user information
  fn update_user(
    &self,
    uid: i64,
    token: &Option<String>,
    params: UpdateUserProfileParams,
  ) -> FutureResult<(), FlowyError>;

  /// Get the user information using the user's token
  fn get_user_profile(
    &self,
    token: Option<String>,
    uid: i64,
  ) -> FutureResult<Option<UserProfile>, FlowyError>;
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum UserEvent {
  /// Only use when the [AuthType] is Local or SelfHosted
  /// Logging into an account using a register email and password
  #[event(input = "SignInPayloadPB", output = "UserProfilePB")]
  SignIn = 0,

  /// Only use when the [AuthType] is Local or SelfHosted
  /// Creating a new account
  #[event(input = "SignUpPayloadPB", output = "UserProfilePB")]
  SignUp = 1,

  /// Logging out fo an account
  #[event(input = "SignOutPB")]
  SignOut = 2,

  /// Update the user information
  #[event(input = "UpdateUserProfilePayloadPB")]
  UpdateUserProfile = 3,

  /// Get the user information
  #[event(output = "UserProfilePB")]
  GetUserProfile = 4,

  /// Check the user current session is valid or not
  #[event(output = "UserProfilePB")]
  CheckUser = 5,

  /// Initialize resources for the current user after launching the application
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

  #[event(input = "ThirdPartyAuthPB", output = "UserProfilePB")]
  ThirdPartyAuth = 10,
}
