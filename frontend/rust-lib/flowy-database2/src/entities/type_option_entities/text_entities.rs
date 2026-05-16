use collab_database::fields::text_type_option::RichTextTypeOption;
use flowy_derive::ProtoBuf;

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RichTextTypeOptionPB {
  #[pb(index = 1)]
  data: String,
}

impl From<RichTextTypeOption> for RichTextTypeOptionPB {
  fn from(_data: RichTextTypeOption) -> Self {
    RichTextTypeOptionPB {
      data: "".to_string(),
    }
  }
}

impl From<RichTextTypeOptionPB> for RichTextTypeOption {
  fn from(_data: RichTextTypeOptionPB) -> Self {
    RichTextTypeOption
  }
}
