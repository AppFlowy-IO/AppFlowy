use crate::services::filter::{Filter, FromFilterString};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use serde::{Deserialize, Serialize};
use std::str::FromStr;

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
pub struct DateFilterContentPB {
  pub start: Option<i64>,
  pub end: Option<i64>,
  pub timestamp: Option<i64>,
}

impl ToString for DateFilterContentPB {
  fn to_string(&self) -> String {
    serde_json::to_string(self).unwrap()
  }
}

impl FromStr for DateFilterContentPB {
  type Err = serde_json::Error;

  fn from_str(s: &str) -> Result<Self, Self::Err> {
    serde_json::from_str(s)
  }
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
#[derive(Default)]
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
      _ => Err(ErrorCode::InvalidData),
    }
  }
}
impl FromFilterString for DateFilterPB {
  fn from_filter(filter: &Filter) -> Self
  where
    Self: Sized,
  {
    let condition = DateFilterConditionPB::try_from(filter.condition as u8)
      .unwrap_or(DateFilterConditionPB::DateIs);
    let mut date_filter = DateFilterPB {
      condition,
      ..Default::default()
    };

    if let Ok(content) = DateFilterContentPB::from_str(&filter.content) {
      date_filter.start = content.start;
      date_filter.end = content.end;
      date_filter.timestamp = content.timestamp;
    };

    date_filter
  }
}
impl std::convert::From<&Filter> for DateFilterPB {
  fn from(filter: &Filter) -> Self {
    let condition = DateFilterConditionPB::try_from(filter.condition as u8)
      .unwrap_or(DateFilterConditionPB::DateIs);
    let mut date_filter = DateFilterPB {
      condition,
      ..Default::default()
    };

    if let Ok(content) = DateFilterContentPB::from_str(&filter.content) {
      date_filter.start = content.start;
      date_filter.end = content.end;
      date_filter.timestamp = content.timestamp;
    };

    date_filter
  }
}
