use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
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
