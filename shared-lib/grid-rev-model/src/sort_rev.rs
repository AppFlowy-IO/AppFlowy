use crate::FieldTypeRevision;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq, Hash)]
pub struct SortRevision {
    pub id: String,
    pub field_id: String,
    pub field_type: FieldTypeRevision,
    pub condition: u8,
}
