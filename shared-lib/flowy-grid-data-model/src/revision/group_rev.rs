use crate::revision::FieldTypeRevision;
use indexmap::IndexMap;
use serde::{Deserialize, Serialize};
use std::sync::Arc;

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
pub struct GridGroupRevision {
    pub id: String,
    pub field_id: String,
    pub sub_field_id: Option<String>,
}
