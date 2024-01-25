use crate::entities::AuthenticatorPB;
use flowy_derive::ProtoBuf;

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

  #[pb(index = 1-)]
  pub stability_ai_key: String,
}
