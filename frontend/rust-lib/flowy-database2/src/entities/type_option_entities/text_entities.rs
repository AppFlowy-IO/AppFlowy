use crate::services::field::RichTextTypeOption;
use flowy_derive::ProtoBuf;

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RichTextTypeOptionPB {
  #[pb(index = 1)]
  data: String,
}

impl From<RichTextTypeOption> for RichTextTypeOptionPB {
  fn from(data: RichTextTypeOption) -> Self {
    Self { data: data.inner }
  }
}

impl From<RichTextTypeOptionPB> for RichTextTypeOption {
  fn from(data: RichTextTypeOptionPB) -> Self {
    Self { inner: data.data }
  }
}
