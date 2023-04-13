use crate::services::field::CheckboxTypeOption;
use flowy_derive::ProtoBuf;

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct CheckboxTypeOptionPB {
  #[pb(index = 1)]
  pub is_selected: bool,
}

impl From<CheckboxTypeOption> for CheckboxTypeOptionPB {
  fn from(data: CheckboxTypeOption) -> Self {
    Self {
      is_selected: data.is_selected,
    }
  }
}

impl From<CheckboxTypeOptionPB> for CheckboxTypeOption {
  fn from(data: CheckboxTypeOptionPB) -> Self {
    Self {
      is_selected: data.is_selected,
    }
  }
}
