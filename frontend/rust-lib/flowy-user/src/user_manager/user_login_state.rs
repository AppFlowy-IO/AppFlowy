use crate::migrations::AnonUser;
use flowy_user_pub::entities::{AuthResponse, AuthType, UserProfile};

/// recording the intermediate state of the sign-in/sign-up process
#[derive(Clone)]
pub struct UserAuthProcess {
  pub user_profile: UserProfile,
  pub response: AuthResponse,
  pub authenticator: AuthType,
  pub migration_user: Option<AnonUser>,
}
