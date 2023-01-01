use crate::services::filter::FromFilterString;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use grid_rev_model::FilterRevision;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct NumberFilterPB {
    #[pb(index = 1)]
    pub condition: NumberFilterConditionPB,

    #[pb(index = 2)]
    pub content: String,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum NumberFilterConditionPB {
    Equal = 0,
    NotEqual = 1,
    GreaterThan = 2,
    LessThan = 3,
    GreaterThanOrEqualTo = 4,
    LessThanOrEqualTo = 5,
    NumberIsEmpty = 6,
    NumberIsNotEmpty = 7,
}

impl std::default::Default for NumberFilterConditionPB {
    fn default() -> Self {
        NumberFilterConditionPB::Equal
    }
}

impl std::convert::From<NumberFilterConditionPB> for u32 {
    fn from(value: NumberFilterConditionPB) -> Self {
        value as u32
    }
}
impl std::convert::TryFrom<u8> for NumberFilterConditionPB {
    type Error = ErrorCode;

    fn try_from(n: u8) -> Result<Self, Self::Error> {
        match n {
            0 => Ok(NumberFilterConditionPB::Equal),
            1 => Ok(NumberFilterConditionPB::NotEqual),
            2 => Ok(NumberFilterConditionPB::GreaterThan),
            3 => Ok(NumberFilterConditionPB::LessThan),
            4 => Ok(NumberFilterConditionPB::GreaterThanOrEqualTo),
            5 => Ok(NumberFilterConditionPB::LessThanOrEqualTo),
            6 => Ok(NumberFilterConditionPB::NumberIsEmpty),
            7 => Ok(NumberFilterConditionPB::NumberIsNotEmpty),
            _ => Err(ErrorCode::InvalidData),
        }
    }
}

impl FromFilterString for NumberFilterPB {
    fn from_filter_rev(filter_rev: &FilterRevision) -> Self
    where
        Self: Sized,
    {
        NumberFilterPB {
            condition: NumberFilterConditionPB::try_from(filter_rev.condition)
                .unwrap_or(NumberFilterConditionPB::Equal),
            content: filter_rev.content.clone(),
        }
    }
}
impl std::convert::From<&FilterRevision> for NumberFilterPB {
    fn from(rev: &FilterRevision) -> Self {
        NumberFilterPB {
            condition: NumberFilterConditionPB::try_from(rev.condition).unwrap_or(NumberFilterConditionPB::Equal),
            content: rev.content.clone(),
        }
    }
}
