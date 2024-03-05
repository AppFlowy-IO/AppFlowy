use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

use crate::services::filter::ParseFilterData;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct TextFilterPB {
  #[pb(index = 1)]
  pub condition: TextFilterConditionPB,

  #[pb(index = 2)]
  pub content: String,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum TextFilterConditionPB {
  #[default]
  TextIs = 0,
  TextIsNot = 1,
  TextContains = 2,
  TextDoesNotContain = 3,
  TextStartsWith = 4,
  TextEndsWith = 5,
  TextIsEmpty = 6,
  TextIsNotEmpty = 7,
}

impl std::convert::From<TextFilterConditionPB> for u32 {
  fn from(value: TextFilterConditionPB) -> Self {
    value as u32
  }
}

impl std::convert::TryFrom<u8> for TextFilterConditionPB {
  type Error = ErrorCode;

  fn try_from(value: u8) -> Result<Self, Self::Error> {
    match value {
      0 => Ok(TextFilterConditionPB::TextIs),
      1 => Ok(TextFilterConditionPB::TextIsNot),
      2 => Ok(TextFilterConditionPB::TextContains),
      3 => Ok(TextFilterConditionPB::TextDoesNotContain),
      4 => Ok(TextFilterConditionPB::TextStartsWith),
      5 => Ok(TextFilterConditionPB::TextEndsWith),
      6 => Ok(TextFilterConditionPB::TextIsEmpty),
      7 => Ok(TextFilterConditionPB::TextIsNotEmpty),
      _ => Err(ErrorCode::InvalidParams),
    }
  }
}

impl ParseFilterData for TextFilterPB {
  fn parse(condition: u8, content: String) -> Self {
    Self {
      condition: TextFilterConditionPB::try_from(condition)
        .unwrap_or(TextFilterConditionPB::TextIs),
      content,
    }
  }
}
