use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
pub struct GridGroupRevision {
    pub id: String,
    pub field_id: String,
    pub sub_field_id: Option<String>,
}
