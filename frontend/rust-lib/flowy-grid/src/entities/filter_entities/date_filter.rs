use crate::entities::parser::NotEmptyStr;
use crate::entities::FieldType;
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
}

#[derive(ProtoBuf, Default, Clone, Debug)]
pub struct CreateGridDateFilterPayload {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub field_type: FieldType,

    #[pb(index = 3)]
    pub condition: DateFilterCondition,

    #[pb(index = 4, one_of)]
    pub start: Option<i64>,

    #[pb(index = 5, one_of)]
    pub end: Option<i64>,
}

pub struct CreateGridDateFilterParams {
    pub field_id: String,

    pub field_type: FieldType,

    pub condition: DateFilterCondition,

    pub start: Option<i64>,

    pub end: Option<i64>,
}

impl TryInto<CreateGridDateFilterParams> for CreateGridDateFilterPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateGridDateFilterParams, Self::Error> {
        let field_id = NotEmptyStr::parse(self.field_id)
            .map_err(|_| ErrorCode::FieldIdIsEmpty)?
            .0;
        Ok(CreateGridDateFilterParams {
            field_id,
            condition: self.condition,
            start: self.start,
            field_type: self.field_type,
            end: self.end,
        })
    }
}

#[derive(Serialize, Deserialize, Default)]
struct DateRange {
    start: Option<i64>,
    end: Option<i64>,
}

impl ToString for DateRange {
    fn to_string(&self) -> String {
        serde_json::to_string(self).unwrap_or_else(|_| "".to_string())
    }
}

impl FromStr for DateRange {
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
impl std::convert::From<Arc<FilterRevision>> for DateFilterPB {
    fn from(rev: Arc<FilterRevision>) -> Self {
        let condition = DateFilterCondition::try_from(rev.condition).unwrap_or(DateFilterCondition::DateIs);
        let mut filter = DateFilterPB {
            condition,
            ..Default::default()
        };

        if let Some(range) = rev
            .content
            .as_ref()
            .and_then(|content| DateRange::from_str(content).ok())
        {
            filter.start = range.start;
            filter.end = range.end;
        };

        filter
    }
}
