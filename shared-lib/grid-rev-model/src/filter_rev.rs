use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq, Hash)]
pub struct FilterRevision {
    pub id: String,
    pub field_id: String,
    pub condition: u8,
    pub content: Option<String>,
}
