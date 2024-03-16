use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

use crate::services::filter::ParseFilterData;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct ChecklistFilterPB {
  #[pb(index = 1)]
  pub condition: ChecklistFilterConditionPB,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum ChecklistFilterConditionPB {
  #[default]
  IsComplete = 0,
  IsIncomplete = 1,
}

impl std::convert::From<ChecklistFilterConditionPB> for u32 {
  fn from(value: ChecklistFilterConditionPB) -> Self {
    value as u32
  }
}

impl std::convert::TryFrom<u8> for ChecklistFilterConditionPB {
  type Error = ErrorCode;

  fn try_from(value: u8) -> Result<Self, Self::Error> {
    match value {
      0 => Ok(ChecklistFilterConditionPB::IsComplete),
      1 => Ok(ChecklistFilterConditionPB::IsIncomplete),
      _ => Err(ErrorCode::InvalidParams),
    }
  }
}

impl ParseFilterData for ChecklistFilterPB {
  fn parse(condition: u8, _content: String) -> Self {
    Self {
      condition: ChecklistFilterConditionPB::try_from(condition)
        .unwrap_or(ChecklistFilterConditionPB::IsIncomplete),
    }
  }
}
