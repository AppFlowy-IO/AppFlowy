use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_user_pub::entities::Authenticator;
use std::collections::HashMap;

#[derive(ProtoBuf, Default)]
pub struct OauthSignInPB {
  /// Use this field to store the third party auth information.
  /// Different auth type has different fields.
  /// Supabase:
  ///   - map: { "uuid": "xxx" }
  ///
  #[pb(index = 1)]
  pub map: HashMap<String, String>,

  #[pb(index = 2)]
  pub authenticator: AuthenticatorPB,
}

#[derive(ProtoBuf_Enum, Eq, PartialEq, Debug, Clone)]
pub enum AuthenticatorPB {
  Local = 0,
  Supabase = 1,
  AppFlowyCloud = 2,
}

impl From<Authenticator> for AuthenticatorPB {
  fn from(auth_type: Authenticator) -> Self {
    match auth_type {
      Authenticator::Supabase => AuthenticatorPB::Supabase,
      Authenticator::Local => AuthenticatorPB::Local,
      Authenticator::AppFlowyCloud => AuthenticatorPB::AppFlowyCloud,
    }
  }
}

impl From<AuthenticatorPB> for Authenticator {
  fn from(pb: AuthenticatorPB) -> Self {
    match pb {
      AuthenticatorPB::Supabase => Authenticator::Supabase,
      AuthenticatorPB::Local => Authenticator::Local,
      AuthenticatorPB::AppFlowyCloud => Authenticator::AppFlowyCloud,
    }
  }
}

impl Default for AuthenticatorPB {
  fn default() -> Self {
    Self::AppFlowyCloud
  }
}

#[derive(ProtoBuf, Default)]
pub struct AddUserPB {
  #[pb(index = 1)]
  pub email: String,

  #[pb(index = 2)]
  pub password: String,
}

#[derive(ProtoBuf, Default)]
pub struct UserSignInPB {
  #[pb(index = 1)]
  pub email: String,

  #[pb(index = 2)]
  pub password: String,
}
