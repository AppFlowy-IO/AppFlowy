use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct CheckboxFilterPB {
  #[pb(index = 1)]
  pub condition: CheckboxFilterConditionPB,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum CheckboxFilterConditionPB {
  #[default]
  IsChecked = 0,
  IsUnChecked = 1,
}

impl std::convert::From<CheckboxFilterConditionPB> for u32 {
  fn from(value: CheckboxFilterConditionPB) -> Self {
    value as u32
  }
}

impl TryFrom<u8> for CheckboxFilterConditionPB {
  type Error = ErrorCode;

  fn try_from(value: u8) -> Result<Self, Self::Error> {
    match value {
      0 => Ok(CheckboxFilterConditionPB::IsChecked),
      1 => Ok(CheckboxFilterConditionPB::IsUnChecked),
      _ => Err(ErrorCode::InvalidParams),
    }
  }
}

impl From<(u8, String)> for CheckboxFilterPB {
  fn from(value: (u8, String)) -> Self {
    CheckboxFilterPB {
      condition: CheckboxFilterConditionPB::try_from(value.0)
        .unwrap_or(CheckboxFilterConditionPB::IsChecked),
    }
  }
}
