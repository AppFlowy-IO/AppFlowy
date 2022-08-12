use crate::revision::FieldTypeRevision;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
pub struct GroupConfigurationRevision {
    pub id: String,
    pub field_id: String,
    pub field_type_rev: FieldTypeRevision,
    pub content: Option<Vec<u8>>,
}
