use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

use crate::services::filter::ParseFilterData;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct NumberFilterPB {
  #[pb(index = 1)]
  pub condition: NumberFilterConditionPB,

  #[pb(index = 2)]
  pub content: String,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum NumberFilterConditionPB {
  #[default]
  Equal = 0,
  NotEqual = 1,
  GreaterThan = 2,
  LessThan = 3,
  GreaterThanOrEqualTo = 4,
  LessThanOrEqualTo = 5,
  NumberIsEmpty = 6,
  NumberIsNotEmpty = 7,
}

impl std::convert::From<NumberFilterConditionPB> for u32 {
  fn from(value: NumberFilterConditionPB) -> Self {
    value as u32
  }
}
impl std::convert::TryFrom<u8> for NumberFilterConditionPB {
  type Error = ErrorCode;

  fn try_from(n: u8) -> Result<Self, Self::Error> {
    match n {
      0 => Ok(NumberFilterConditionPB::Equal),
      1 => Ok(NumberFilterConditionPB::NotEqual),
      2 => Ok(NumberFilterConditionPB::GreaterThan),
      3 => Ok(NumberFilterConditionPB::LessThan),
      4 => Ok(NumberFilterConditionPB::GreaterThanOrEqualTo),
      5 => Ok(NumberFilterConditionPB::LessThanOrEqualTo),
      6 => Ok(NumberFilterConditionPB::NumberIsEmpty),
      7 => Ok(NumberFilterConditionPB::NumberIsNotEmpty),
      _ => Err(ErrorCode::InvalidParams),
    }
  }
}

impl ParseFilterData for NumberFilterPB {
  fn parse(condition: u8, content: String) -> Self {
    NumberFilterPB {
      condition: NumberFilterConditionPB::try_from(condition)
        .unwrap_or(NumberFilterConditionPB::Equal),
      content,
    }
  }
}
