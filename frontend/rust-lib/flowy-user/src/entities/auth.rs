use std::collections::HashMap;
use std::convert::TryInto;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_user_deps::entities::*;

use crate::entities::parser::*;
use crate::errors::ErrorCode;

#[derive(ProtoBuf, Default)]
pub struct SignInPayloadPB {
  #[pb(index = 1)]
  pub email: String,

  #[pb(index = 2)]
  pub password: String,

  #[pb(index = 3)]
  pub name: String,

  #[pb(index = 4)]
  pub auth_type: AuthTypePB,

  #[pb(index = 5)]
  pub device_id: String,
}

impl TryInto<SignInParams> for SignInPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<SignInParams, Self::Error> {
    let email = UserEmail::parse(self.email)?;
    let password = UserPassword::parse(self.password)?;

    Ok(SignInParams {
      email: email.0,
      password: password.0,
      name: self.name,
      auth_type: self.auth_type.into(),
      device_id: self.device_id,
    })
  }
}

#[derive(ProtoBuf, Default)]
pub struct SignUpPayloadPB {
  #[pb(index = 1)]
  pub email: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3)]
  pub password: String,

  #[pb(index = 4)]
  pub auth_type: AuthTypePB,

  #[pb(index = 5)]
  pub device_id: String,
}

impl TryInto<SignUpParams> for SignUpPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<SignUpParams, Self::Error> {
    let email = UserEmail::parse(self.email)?;
    let password = UserPassword::parse(self.password)?;
    let name = UserName::parse(self.name)?;

    Ok(SignUpParams {
      email: email.0,
      name: name.0,
      password: password.0,
      auth_type: self.auth_type.into(),
      device_id: self.device_id,
    })
  }
}

#[derive(ProtoBuf, Default)]
pub struct OAuthPB {
  /// Use this field to store the third party auth information.
  /// Different auth type has different fields.
  /// Supabase:
  ///   - map: { "uuid": "xxx" }
  ///
  #[pb(index = 1)]
  pub map: HashMap<String, String>,

  #[pb(index = 2)]
  pub auth_type: AuthTypePB,
}

#[derive(ProtoBuf, Default)]
pub struct OAuthCallbackRequestPB {
  #[pb(index = 1)]
  pub email: String,

  #[pb(index = 2)]
  pub auth_type: AuthTypePB,
}

#[derive(ProtoBuf, Default)]
pub struct OAuthCallbackResponsePB {
  #[pb(index = 1)]
  pub sign_in_url: String,
}

#[derive(ProtoBuf_Enum, Eq, PartialEq, Debug, Clone)]
pub enum AuthTypePB {
  Local = 0,
  AFCloud = 1,
  Supabase = 2,
}

impl Default for AuthTypePB {
  fn default() -> Self {
    Self::Local
  }
}

#[derive(Debug, ProtoBuf, Default)]
pub struct UserCredentialsPB {
  #[pb(index = 1, one_of)]
  pub uid: Option<i64>,

  #[pb(index = 2, one_of)]
  pub uuid: Option<String>,

  #[pb(index = 3, one_of)]
  pub token: Option<String>,
}

impl UserCredentialsPB {
  pub fn from_uid(uid: i64) -> Self {
    Self {
      uid: Some(uid),
      uuid: None,
      token: None,
    }
  }

  pub fn from_token(token: &str) -> Self {
    Self {
      uid: None,
      uuid: None,
      token: Some(token.to_owned()),
    }
  }

  pub fn from_uuid(uuid: &str) -> Self {
    Self {
      uid: None,
      uuid: Some(uuid.to_owned()),
      token: None,
    }
  }
}

impl From<UserCredentialsPB> for UserCredentials {
  fn from(value: UserCredentialsPB) -> Self {
    Self::new(value.token, value.uid, value.uuid)
  }
}

#[derive(Default, ProtoBuf)]
pub struct UserStatePB {
  #[pb(index = 1)]
  pub auth_type: AuthTypePB,
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct AuthStateChangedPB {
  #[pb(index = 1)]
  pub state: AuthStatePB,
}

#[derive(ProtoBuf_Enum, Debug, Clone)]
pub enum AuthStatePB {
  // adding AuthState prefix to avoid conflict with other enums
  AuthStateUnknown = 0,
  AuthStateSignIn = 1,
  AuthStateSignOut = 2,
  AuthStateForceSignOut = 3,
}

impl Default for AuthStatePB {
  fn default() -> Self {
    Self::AuthStateUnknown
  }
}
