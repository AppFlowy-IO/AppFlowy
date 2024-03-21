use std::str::FromStr;

use serde::{Deserialize, Serialize};

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

use crate::services::filter::ParseFilterData;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct DateFilterPB {
  #[pb(index = 1)]
  pub condition: DateFilterConditionPB,

  #[pb(index = 2, one_of)]
  pub start: Option<i64>,

  #[pb(index = 3, one_of)]
  pub end: Option<i64>,

  #[pb(index = 4, one_of)]
  pub timestamp: Option<i64>,
}

#[derive(Deserialize, Serialize, Default, Clone, Debug)]
pub struct DateFilterContent {
  pub start: Option<i64>,
  pub end: Option<i64>,
  pub timestamp: Option<i64>,
}

impl ToString for DateFilterContent {
  fn to_string(&self) -> String {
    serde_json::to_string(self).unwrap()
  }
}

impl FromStr for DateFilterContent {
  type Err = serde_json::Error;

  fn from_str(s: &str) -> Result<Self, Self::Err> {
    serde_json::from_str(s)
  }
}

#[derive(Debug, Clone, Default, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum DateFilterConditionPB {
  #[default]
  DateIs = 0,
  DateBefore = 1,
  DateAfter = 2,
  DateOnOrBefore = 3,
  DateOnOrAfter = 4,
  DateWithIn = 5,
  DateIsEmpty = 6,
  DateIsNotEmpty = 7,
}

impl std::convert::From<DateFilterConditionPB> for u32 {
  fn from(value: DateFilterConditionPB) -> Self {
    value as u32
  }
}

impl std::convert::TryFrom<u8> for DateFilterConditionPB {
  type Error = ErrorCode;

  fn try_from(value: u8) -> Result<Self, Self::Error> {
    match value {
      0 => Ok(DateFilterConditionPB::DateIs),
      1 => Ok(DateFilterConditionPB::DateBefore),
      2 => Ok(DateFilterConditionPB::DateAfter),
      3 => Ok(DateFilterConditionPB::DateOnOrBefore),
      4 => Ok(DateFilterConditionPB::DateOnOrAfter),
      5 => Ok(DateFilterConditionPB::DateWithIn),
      6 => Ok(DateFilterConditionPB::DateIsEmpty),
      _ => Err(ErrorCode::InvalidParams),
    }
  }
}

impl ParseFilterData for DateFilterPB {
  fn parse(condition: u8, content: String) -> Self {
    let condition =
      DateFilterConditionPB::try_from(condition).unwrap_or(DateFilterConditionPB::DateIs);
    let mut date_filter = Self {
      condition,
      ..Default::default()
    };

    if let Ok(content) = DateFilterContent::from_str(&content) {
      date_filter.start = content.start;
      date_filter.end = content.end;
      date_filter.timestamp = content.timestamp;
    };

    date_filter
  }
}
