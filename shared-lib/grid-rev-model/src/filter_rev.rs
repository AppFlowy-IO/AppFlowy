use crate::FieldTypeRevision;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq, Hash)]
pub struct FilterRevision {
    pub id: String,
    pub field_id: String,
    pub field_type_rev: FieldTypeRevision,
    pub condition: u8,
    #[serde(default)]
    pub content: String,
}
