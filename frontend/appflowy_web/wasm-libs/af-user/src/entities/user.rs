use crate::entities::AuthenticatorPB;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_user_pub::entities::{EncryptionType, UserProfile};

#[derive(ProtoBuf, Default, Eq, PartialEq, Debug, Clone)]
pub struct UserProfilePB {
  #[pb(index = 1)]
  pub id: i64,

  #[pb(index = 2)]
  pub email: String,

  #[pb(index = 3)]
  pub name: String,

  #[pb(index = 4)]
  pub token: String,

  #[pb(index = 5)]
  pub icon_url: String,

  #[pb(index = 6)]
  pub openai_key: String,

  #[pb(index = 7)]
  pub authenticator: AuthenticatorPB,

  #[pb(index = 8)]
  pub encryption_sign: String,

  #[pb(index = 9)]
  pub workspace_id: String,

  #[pb(index = 10)]
  pub stability_ai_key: String,

  #[pb(index = 11)]
  pub ai_model: String,
}

impl From<UserProfile> for UserProfilePB {
  fn from(user_profile: UserProfile) -> Self {
    let (encryption_sign, _encryption_ty) = match user_profile.encryption_type {
      EncryptionType::NoEncryption => ("".to_string(), EncryptionTypePB::NoEncryption),
      EncryptionType::SelfEncryption(sign) => (sign, EncryptionTypePB::Symmetric),
    };
    Self {
      id: user_profile.uid,
      email: user_profile.email,
      name: user_profile.name,
      token: user_profile.token,
      icon_url: user_profile.icon_url,
      openai_key: user_profile.openai_key,
      encryption_sign,
      authenticator: user_profile.authenticator.into(),
      workspace_id: user_profile.workspace_id,
      stability_ai_key: user_profile.stability_ai_key,
      ai_model: user_profile.ai_model,
    }
  }
}

#[derive(ProtoBuf_Enum, Eq, PartialEq, Debug, Clone)]
pub enum EncryptionTypePB {
  NoEncryption = 0,
  Symmetric = 1,
}

impl Default for EncryptionTypePB {
  fn default() -> Self {
    Self::NoEncryption
  }
}
