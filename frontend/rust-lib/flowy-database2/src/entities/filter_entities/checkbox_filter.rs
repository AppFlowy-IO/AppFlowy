use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

use crate::services::filter::{Filter, FromFilterString};

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct CheckboxFilterPB {
  #[pb(index = 1)]
  pub condition: CheckboxFilterConditionPB,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
#[derive(Default)]
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

impl std::convert::TryFrom<u8> for CheckboxFilterConditionPB {
  type Error = ErrorCode;

  fn try_from(value: u8) -> Result<Self, Self::Error> {
    match value {
      0 => Ok(CheckboxFilterConditionPB::IsChecked),
      1 => Ok(CheckboxFilterConditionPB::IsUnChecked),
      _ => Err(ErrorCode::InvalidParams),
    }
  }
}

impl FromFilterString for CheckboxFilterPB {
  fn from_filter(filter: &Filter) -> Self
  where
    Self: Sized,
  {
    CheckboxFilterPB {
      condition: CheckboxFilterConditionPB::try_from(filter.condition as u8)
        .unwrap_or(CheckboxFilterConditionPB::IsChecked),
    }
  }
}

impl std::convert::From<&Filter> for CheckboxFilterPB {
  fn from(filter: &Filter) -> Self {
    CheckboxFilterPB {
      condition: CheckboxFilterConditionPB::try_from(filter.condition as u8)
        .unwrap_or(CheckboxFilterConditionPB::IsChecked),
    }
  }
}
