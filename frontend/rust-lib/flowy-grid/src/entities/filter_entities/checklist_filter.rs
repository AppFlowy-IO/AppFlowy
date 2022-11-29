use crate::services::field::SelectOptionIds;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use grid_rev_model::FilterRevision;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct ChecklistFilterPB {
    #[pb(index = 1)]
    pub condition: ChecklistFilterCondition,

    #[pb(index = 2)]
    pub option_ids: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum ChecklistFilterCondition {
    IsComplete = 0,
    IsIncomplete = 1,
}

impl std::convert::From<ChecklistFilterCondition> for u32 {
    fn from(value: ChecklistFilterCondition) -> Self {
        value as u32
    }
}

impl std::default::Default for ChecklistFilterCondition {
    fn default() -> Self {
        ChecklistFilterCondition::IsIncomplete
    }
}

impl std::convert::TryFrom<u8> for ChecklistFilterCondition {
    type Error = ErrorCode;

    fn try_from(value: u8) -> Result<Self, Self::Error> {
        match value {
            0 => Ok(ChecklistFilterCondition::IsComplete),
            1 => Ok(ChecklistFilterCondition::IsIncomplete),
            _ => Err(ErrorCode::InvalidData),
        }
    }
}

impl std::convert::From<&FilterRevision> for ChecklistFilterPB {
    fn from(rev: &FilterRevision) -> Self {
        let ids = SelectOptionIds::from(rev.content.clone());
        ChecklistFilterPB {
            condition: ChecklistFilterCondition::try_from(rev.condition)
                .unwrap_or(ChecklistFilterCondition::IsIncomplete),
            option_ids: ids.into_inner(),
        }
    }
}
