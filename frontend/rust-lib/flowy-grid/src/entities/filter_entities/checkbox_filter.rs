use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use grid_rev_model::FilterRevision;
use std::sync::Arc;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct CheckboxFilterPB {
    #[pb(index = 1)]
    pub condition: CheckboxCondition,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum CheckboxCondition {
    IsChecked = 0,
    IsUnChecked = 1,
}

impl std::convert::From<CheckboxCondition> for u32 {
    fn from(value: CheckboxCondition) -> Self {
        value as u32
    }
}

impl std::default::Default for CheckboxCondition {
    fn default() -> Self {
        CheckboxCondition::IsChecked
    }
}

impl std::convert::TryFrom<u8> for CheckboxCondition {
    type Error = ErrorCode;

    fn try_from(value: u8) -> Result<Self, Self::Error> {
        match value {
            0 => Ok(CheckboxCondition::IsChecked),
            1 => Ok(CheckboxCondition::IsUnChecked),
            _ => Err(ErrorCode::InvalidData),
        }
    }
}

impl std::convert::From<Arc<FilterRevision>> for CheckboxFilterPB {
    fn from(rev: Arc<FilterRevision>) -> Self {
        CheckboxFilterPB {
            condition: CheckboxCondition::try_from(rev.condition).unwrap_or(CheckboxCondition::IsChecked),
        }
    }
}
