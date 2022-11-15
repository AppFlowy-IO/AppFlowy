use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use grid_rev_model::FilterRevision;
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use std::sync::Arc;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct DateFilterPB {
    #[pb(index = 1)]
    pub condition: DateFilterCondition,

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

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum DateFilterCondition {
    DateIs = 0,
    DateBefore = 1,
    DateAfter = 2,
    DateOnOrBefore = 3,
    DateOnOrAfter = 4,
    DateWithIn = 5,
    DateIsEmpty = 6,
    DateIsNotEmpty = 7,
}

impl std::convert::From<DateFilterCondition> for u32 {
    fn from(value: DateFilterCondition) -> Self {
        value as u32
    }
}
impl std::default::Default for DateFilterCondition {
    fn default() -> Self {
        DateFilterCondition::DateIs
    }
}

impl std::convert::TryFrom<u8> for DateFilterCondition {
    type Error = ErrorCode;

    fn try_from(value: u8) -> Result<Self, Self::Error> {
        match value {
            0 => Ok(DateFilterCondition::DateIs),
            1 => Ok(DateFilterCondition::DateBefore),
            2 => Ok(DateFilterCondition::DateAfter),
            3 => Ok(DateFilterCondition::DateOnOrBefore),
            4 => Ok(DateFilterCondition::DateOnOrAfter),
            5 => Ok(DateFilterCondition::DateWithIn),
            6 => Ok(DateFilterCondition::DateIsEmpty),
            _ => Err(ErrorCode::InvalidData),
        }
    }
}
impl std::convert::From<&FilterRevision> for DateFilterPB {
    fn from(rev: &FilterRevision) -> Self {
        let condition = DateFilterCondition::try_from(rev.condition).unwrap_or(DateFilterCondition::DateIs);
        let mut filter = DateFilterPB {
            condition,
            ..Default::default()
        };

        if let Ok(content) = DateFilterContent::from_str(&rev.content) {
            filter.start = content.start;
            filter.end = content.end;
            filter.timestamp = content.timestamp;
        };

        filter
    }
}
