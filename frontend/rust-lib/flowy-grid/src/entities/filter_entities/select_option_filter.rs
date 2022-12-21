use crate::services::field::SelectOptionIds;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use grid_rev_model::FilterRevision;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct SelectOptionFilterPB {
    #[pb(index = 1)]
    pub condition: SelectOptionConditionPB,

    #[pb(index = 2)]
    pub option_ids: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum SelectOptionConditionPB {
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

impl std::default::Default for SelectOptionConditionPB {
    fn default() -> Self {
        SelectOptionConditionPB::OptionIs
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
            _ => Err(ErrorCode::InvalidData),
        }
    }
}

impl std::convert::From<&FilterRevision> for SelectOptionFilterPB {
    fn from(rev: &FilterRevision) -> Self {
        let ids = SelectOptionIds::from(rev.content.clone());
        SelectOptionFilterPB {
            condition: SelectOptionConditionPB::try_from(rev.condition).unwrap_or(SelectOptionConditionPB::OptionIs),
            option_ids: ids.into_inner(),
        }
    }
}
