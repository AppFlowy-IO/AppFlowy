use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use flowy_grid_data_model::revision::GridFilterRevision;
use std::sync::Arc;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridDateFilter {
    #[pb(index = 1)]
    pub condition: DateFilterCondition,

    #[pb(index = 2, one_of)]
    pub content: Option<String>,
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
impl std::convert::From<Arc<GridFilterRevision>> for GridDateFilter {
    fn from(rev: Arc<GridFilterRevision>) -> Self {
        GridDateFilter {
            condition: DateFilterCondition::try_from(rev.condition).unwrap_or(DateFilterCondition::DateIs),
            content: rev.content.clone(),
        }
    }
}
