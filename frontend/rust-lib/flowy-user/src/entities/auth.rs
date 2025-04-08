use std::collections::HashMap;
use std::convert::TryInto;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_user_pub::entities::*;

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
  pub auth_type: AuthenticatorPB,

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
  pub auth_type: AuthenticatorPB,

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
pub struct MagicLinkSignInPB {
  #[pb(index = 1)]
  pub email: String,

  #[pb(index = 2)]
  pub redirect_to: String,
}

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

#[derive(ProtoBuf, Default)]
pub struct SignInUrlPayloadPB {
  #[pb(index = 1)]
  pub email: String,

  #[pb(index = 2)]
  pub authenticator: AuthenticatorPB,
}

#[derive(ProtoBuf, Default)]
pub struct SignInUrlPB {
  #[pb(index = 1)]
  pub sign_in_url: String,
}

#[derive(ProtoBuf, Default)]
pub struct OauthProviderPB {
  #[pb(index = 1)]
  pub provider: ProviderTypePB,
}

#[derive(ProtoBuf_Enum, Eq, PartialEq, Debug, Clone, Default)]
pub enum ProviderTypePB {
  Apple = 0,
  Azure = 1,
  Bitbucket = 2,
  Discord = 3,
  Facebook = 4,
  Figma = 5,
  Github = 6,
  Gitlab = 7,
  #[default]
  Google = 8,
  Keycloak = 9,
  Kakao = 10,
  Linkedin = 11,
  Notion = 12,
  Spotify = 13,
  Slack = 14,
  Workos = 15,
  Twitch = 16,
  Twitter = 17,
  Email = 18,
  Phone = 19,
  Zoom = 20,
}

impl ProviderTypePB {
  pub fn as_str(&self) -> &str {
    match self {
      ProviderTypePB::Apple => "apple",
      ProviderTypePB::Azure => "azure",
      ProviderTypePB::Bitbucket => "bitbucket",
      ProviderTypePB::Discord => "discord",
      ProviderTypePB::Facebook => "facebook",
      ProviderTypePB::Figma => "figma",
      ProviderTypePB::Github => "github",
      ProviderTypePB::Gitlab => "gitlab",
      ProviderTypePB::Google => "google",
      ProviderTypePB::Keycloak => "keycloak",
      ProviderTypePB::Kakao => "kakao",
      ProviderTypePB::Linkedin => "linkedin",
      ProviderTypePB::Notion => "notion",
      ProviderTypePB::Spotify => "spotify",
      ProviderTypePB::Slack => "slack",
      ProviderTypePB::Workos => "workos",
      ProviderTypePB::Twitch => "twitch",
      ProviderTypePB::Twitter => "twitter",
      ProviderTypePB::Email => "email",
      ProviderTypePB::Phone => "phone",
      ProviderTypePB::Zoom => "zoom",
    }
  }
}

#[derive(ProtoBuf, Default)]
pub struct OauthProviderDataPB {
  #[pb(index = 1)]
  pub oauth_url: String,
}

#[repr(u8)]
#[derive(ProtoBuf_Enum, Eq, PartialEq, Debug, Clone)]
pub enum AuthenticatorPB {
  Local = 0,
  AppFlowyCloud = 2,
}

impl From<Authenticator> for AuthenticatorPB {
  fn from(auth_type: Authenticator) -> Self {
    match auth_type {
      Authenticator::Local => AuthenticatorPB::Local,
      Authenticator::AppFlowyCloud => AuthenticatorPB::AppFlowyCloud,
    }
  }
}

impl From<AuthenticatorPB> for Authenticator {
  fn from(pb: AuthenticatorPB) -> Self {
    match pb {
      AuthenticatorPB::Local => Authenticator::Local,
      AuthenticatorPB::AppFlowyCloud => Authenticator::AppFlowyCloud,
    }
  }
}

impl Default for AuthenticatorPB {
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
  pub auth_type: AuthenticatorPB,
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct AuthStateChangedPB {
  #[pb(index = 1)]
  pub state: AuthStatePB,

  #[pb(index = 2)]
  pub message: String,
}

#[derive(ProtoBuf_Enum, Debug, Clone)]
pub enum AuthStatePB {
  // adding AuthState prefix to avoid conflict with other enums
  AuthStateUnknown = 0,
  AuthStateSignIn = 1,
  AuthStateSignOut = 2,
  InvalidAuth = 3,
}

impl Default for AuthStatePB {
  fn default() -> Self {
    Self::AuthStateUnknown
  }
}
