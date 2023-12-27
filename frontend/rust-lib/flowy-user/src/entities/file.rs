use crate::entities::required_not_empty_str;
use flowy_derive::ProtoBuf;
use validator::Validate;

#[derive(ProtoBuf, Validate, Default)]
pub struct SyncAppFlowyDataPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub path: String,
}
