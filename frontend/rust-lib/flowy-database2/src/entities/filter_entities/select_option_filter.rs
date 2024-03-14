use std::str::FromStr;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

use crate::services::{field::SelectOptionIds, filter::ParseFilterData};

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct SelectOptionFilterPB {
  #[pb(index = 1)]
  pub condition: SelectOptionConditionPB,

  #[pb(index = 2)]
  pub option_ids: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
#[derive(Default)]
pub enum SelectOptionConditionPB {
  #[default]
  OptionIs = 0,
  OptionIsNot = 1,
  OptionIsEmpty = 2,
  OptionIsNotEmpty = 3,
}

impl std::convert::From<SelectOptionConditionPB> for u32 {
  fn from(value: SelectOptionConditionPB) -> Self {
    value as u32
  }
}

impl std::convert::TryFrom<u8> for SelectOptionConditionPB {
  type Error = ErrorCode;

  fn try_from(value: u8) -> Result<Self, Self::Error> {
    match value {
      0 => Ok(SelectOptionConditionPB::OptionIs),
      1 => Ok(SelectOptionConditionPB::OptionIsNot),
      2 => Ok(SelectOptionConditionPB::OptionIsEmpty),
      3 => Ok(SelectOptionConditionPB::OptionIsNotEmpty),
      _ => Err(ErrorCode::InvalidParams),
    }
  }
}
impl ParseFilterData for SelectOptionFilterPB {
  fn parse(condition: u8, content: String) -> Self {
    Self {
      condition: SelectOptionConditionPB::try_from(condition)
        .unwrap_or(SelectOptionConditionPB::OptionIs),
      option_ids: SelectOptionIds::from_str(&content)
        .unwrap_or_default()
        .into_inner(),
    }
  }
}
