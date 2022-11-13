use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use grid_rev_model::FilterRevision;

use std::sync::Arc;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct NumberFilterPB {
    #[pb(index = 1)]
    pub condition: NumberFilterCondition,

    #[pb(index = 2, one_of)]
    pub content: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum NumberFilterCondition {
    Equal = 0,
    NotEqual = 1,
    GreaterThan = 2,
    LessThan = 3,
    GreaterThanOrEqualTo = 4,
    LessThanOrEqualTo = 5,
    NumberIsEmpty = 6,
    NumberIsNotEmpty = 7,
}

impl std::default::Default for NumberFilterCondition {
    fn default() -> Self {
        NumberFilterCondition::Equal
    }
}

impl std::convert::From<NumberFilterCondition> for u32 {
    fn from(value: NumberFilterCondition) -> Self {
        value as u32
    }
}
impl std::convert::TryFrom<u8> for NumberFilterCondition {
    type Error = ErrorCode;

    fn try_from(n: u8) -> Result<Self, Self::Error> {
        match n {
            0 => Ok(NumberFilterCondition::Equal),
            1 => Ok(NumberFilterCondition::NotEqual),
            2 => Ok(NumberFilterCondition::GreaterThan),
            3 => Ok(NumberFilterCondition::LessThan),
            4 => Ok(NumberFilterCondition::GreaterThanOrEqualTo),
            5 => Ok(NumberFilterCondition::LessThanOrEqualTo),
            6 => Ok(NumberFilterCondition::NumberIsEmpty),
            7 => Ok(NumberFilterCondition::NumberIsNotEmpty),
            _ => Err(ErrorCode::InvalidData),
        }
    }
}

impl std::convert::From<Arc<FilterRevision>> for NumberFilterPB {
    fn from(rev: Arc<FilterRevision>) -> Self {
        NumberFilterPB {
            condition: NumberFilterCondition::try_from(rev.condition).unwrap_or(NumberFilterCondition::Equal),
            content: rev.content.clone(),
        }
    }
}
