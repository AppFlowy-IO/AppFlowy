use crate::services::field::CheckboxTypeOption;
use flowy_derive::ProtoBuf;

#[derive(Default, Debug, Clone, ProtoBuf)]
pub struct CheckboxCellDataPB {
  #[pb(index = 1)]
  pub is_checked: bool,
}

impl CheckboxCellDataPB {
  pub fn new(is_checked: bool) -> Self {
    Self { is_checked }
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct CheckboxTypeOptionPB {
  /// unused
  #[pb(index = 1)]
  pub dummy_field: bool,
}

impl From<CheckboxTypeOption> for CheckboxTypeOptionPB {
  fn from(_type_option: CheckboxTypeOption) -> Self {
    Self { dummy_field: false }
  }
}

impl From<CheckboxTypeOptionPB> for CheckboxTypeOption {
  fn from(_type_option: CheckboxTypeOptionPB) -> Self {
    Self()
  }
}
