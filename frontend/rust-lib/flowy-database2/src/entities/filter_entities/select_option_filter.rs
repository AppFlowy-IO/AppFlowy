use std::str::FromStr;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

use crate::services::{field::SelectOptionIds, filter::ParseFilterData};

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct SelectOptionFilterPB {
  #[pb(index = 1)]
  pub condition: SelectOptionFilterConditionPB,

  #[pb(index = 2)]
  pub option_ids: Vec<String>,
}

#[derive(Debug, Default, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum SelectOptionFilterConditionPB {
  #[default]
  OptionIs = 0,
  OptionIsNot = 1,
  OptionContains = 2,
  OptionDoesNotContain = 3,
  OptionIsEmpty = 4,
  OptionIsNotEmpty = 5,
}

impl From<SelectOptionFilterConditionPB> for u32 {
  fn from(value: SelectOptionFilterConditionPB) -> Self {
    value as u32
  }
}

impl TryFrom<u8> for SelectOptionFilterConditionPB {
  type Error = ErrorCode;

  fn try_from(value: u8) -> Result<Self, Self::Error> {
    match value {
      0 => Ok(SelectOptionFilterConditionPB::OptionIs),
      1 => Ok(SelectOptionFilterConditionPB::OptionIsNot),
      2 => Ok(SelectOptionFilterConditionPB::OptionContains),
      3 => Ok(SelectOptionFilterConditionPB::OptionDoesNotContain),
      4 => Ok(SelectOptionFilterConditionPB::OptionIsEmpty),
      5 => Ok(SelectOptionFilterConditionPB::OptionIsNotEmpty),
      _ => Err(ErrorCode::InvalidParams),
    }
  }
}
impl ParseFilterData for SelectOptionFilterPB {
  fn parse(condition: u8, content: String) -> Self {
    Self {
      condition: SelectOptionFilterConditionPB::try_from(condition)
        .unwrap_or(SelectOptionFilterConditionPB::OptionIs),
      option_ids: SelectOptionIds::from_str(&content)
        .unwrap_or_default()
        .into_inner(),
    }
  }
}
