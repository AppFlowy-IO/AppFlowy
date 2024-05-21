use flowy_derive::ProtoBuf;
use lib_infra::validator_fn::{required_not_empty_str, required_valid_path};
use validator::Validate;

#[derive(Default, ProtoBuf, Validate, Clone, Debug)]
pub struct SendChatPayloadPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub chat_id: String,

  #[pb(index = 2)]
  #[validate(custom = "required_not_empty_str")]
  pub message: String,
}
