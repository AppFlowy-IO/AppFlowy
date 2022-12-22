use crate::FieldTypeRevision;
use serde::{Deserialize, Serialize};
use serde_repr::*;

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq, Hash)]
pub struct SortRevision {
    pub id: String,
    pub field_id: String,
    pub field_type: FieldTypeRevision,
    pub condition: SortCondition,
}

#[derive(Serialize_repr, Deserialize_repr, PartialEq, Eq, Hash, Clone, Debug)]
#[repr(u8)]
pub enum SortCondition {
    Ascending = 0,
    Descending = 1,
}

impl std::convert::From<u8> for SortCondition {
    fn from(num: u8) -> Self {
        match num {
            0 => SortCondition::Ascending,
            1 => SortCondition::Descending,
            _ => SortCondition::Ascending,
        }
    }
}

impl std::default::Default for SortCondition {
    fn default() -> Self {
        Self::Ascending
    }
}
