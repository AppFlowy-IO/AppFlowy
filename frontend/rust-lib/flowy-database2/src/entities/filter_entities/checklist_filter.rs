use crate::services::filter::{Filter, FromFilterString};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct ChecklistFilterPB {
  #[pb(index = 1)]
  pub condition: ChecklistFilterConditionPB,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
#[derive(Default)]
pub enum ChecklistFilterConditionPB {
  IsComplete = 0,
  #[default]
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
      _ => Err(ErrorCode::InvalidData),
    }
  }
}

impl FromFilterString for ChecklistFilterPB {
  fn from_filter(filter: &Filter) -> Self
  where
    Self: Sized,
  {
    ChecklistFilterPB {
      condition: ChecklistFilterConditionPB::try_from(filter.condition as u8)
        .unwrap_or(ChecklistFilterConditionPB::IsIncomplete),
    }
  }
}

impl std::convert::From<&Filter> for ChecklistFilterPB {
  fn from(filter: &Filter) -> Self {
    ChecklistFilterPB {
      condition: ChecklistFilterConditionPB::try_from(filter.condition as u8)
        .unwrap_or(ChecklistFilterConditionPB::IsIncomplete),
    }
  }
}
