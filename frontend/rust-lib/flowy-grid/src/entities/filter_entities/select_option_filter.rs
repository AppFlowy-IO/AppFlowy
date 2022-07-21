use crate::services::field::SelectOptionIds;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use flowy_grid_data_model::revision::GridFilterRevision;
use std::sync::Arc;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridSelectOptionFilter {
    #[pb(index = 1)]
    pub condition: SelectOptionCondition,

    #[pb(index = 2)]
    pub option_ids: Vec<String>,
}
#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum SelectOptionCondition {
    OptionIs = 0,
    OptionIsNot = 1,
    OptionIsEmpty = 2,
    OptionIsNotEmpty = 3,
}

impl std::convert::From<SelectOptionCondition> for i32 {
    fn from(value: SelectOptionCondition) -> Self {
        value as i32
    }
}

impl std::default::Default for SelectOptionCondition {
    fn default() -> Self {
        SelectOptionCondition::OptionIs
    }
}

impl std::convert::TryFrom<u8> for SelectOptionCondition {
    type Error = ErrorCode;

    fn try_from(value: u8) -> Result<Self, Self::Error> {
        match value {
            0 => Ok(SelectOptionCondition::OptionIs),
            1 => Ok(SelectOptionCondition::OptionIsNot),
            2 => Ok(SelectOptionCondition::OptionIsEmpty),
            3 => Ok(SelectOptionCondition::OptionIsNotEmpty),
            _ => Err(ErrorCode::InvalidData),
        }
    }
}

impl std::convert::From<Arc<GridFilterRevision>> for GridSelectOptionFilter {
    fn from(rev: Arc<GridFilterRevision>) -> Self {
        let ids = SelectOptionIds::from(rev.content.clone());
        GridSelectOptionFilter {
            condition: SelectOptionCondition::try_from(rev.condition).unwrap_or(SelectOptionCondition::OptionIs),
            option_ids: ids.into_inner(),
        }
    }
}
