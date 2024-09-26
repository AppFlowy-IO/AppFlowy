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
  DateStartsOn = 0,
  DateStartsBefore = 1,
  DateStartsAfter = 2,
  DateStartsOnOrBefore = 3,
  DateStartsOnOrAfter = 4,
  DateStartsBetween = 5,
  DateStartIsEmpty = 6,
  DateStartIsNotEmpty = 7,
  DateEndsOn = 8,
  DateEndsBefore = 9,
  DateEndsAfter = 10,
  DateEndsOnOrBefore = 11,
  DateEndsOnOrAfter = 12,
  DateEndsBetween = 13,
  DateEndIsEmpty = 14,
  DateEndIsNotEmpty = 15,
}

impl DateFilterConditionPB {
  pub fn is_filter_on_start_timestamp(&self) -> bool {
    matches!(
      self,
      Self::DateStartsOn
        | Self::DateStartsBefore
        | Self::DateStartsAfter
        | Self::DateStartsOnOrBefore
        | Self::DateStartsOnOrAfter
        | Self::DateStartsBetween
        | Self::DateStartIsEmpty
        | Self::DateStartIsNotEmpty,
    )
  }
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
      0 => Ok(Self::DateStartsOn),
      1 => Ok(Self::DateStartsBefore),
      2 => Ok(Self::DateStartsAfter),
      3 => Ok(Self::DateStartsOnOrBefore),
      4 => Ok(Self::DateStartsOnOrAfter),
      5 => Ok(Self::DateStartsBetween),
      6 => Ok(Self::DateStartIsEmpty),
      7 => Ok(Self::DateStartIsNotEmpty),
      8 => Ok(Self::DateEndsOn),
      9 => Ok(Self::DateEndsBefore),
      10 => Ok(Self::DateEndsAfter),
      11 => Ok(Self::DateEndsOnOrBefore),
      12 => Ok(Self::DateEndsOnOrAfter),
      13 => Ok(Self::DateEndsBetween),
      14 => Ok(Self::DateEndIsEmpty),
      15 => Ok(Self::DateEndIsNotEmpty),
      _ => Err(ErrorCode::InvalidParams),
    }
  }
}

impl ParseFilterData for DateFilterPB {
  fn parse(condition: u8, content: String) -> Self {
    let condition =
      DateFilterConditionPB::try_from(condition).unwrap_or(DateFilterConditionPB::DateStartsOn);
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

impl DateFilterPB {
  pub fn remove_end_date_conditions(self) -> Self {
    if self.condition.is_filter_on_start_timestamp() {
      self
    } else {
      Self::default()
    }
  }
}
