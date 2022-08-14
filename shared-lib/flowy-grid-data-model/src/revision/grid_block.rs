use indexmap::IndexMap;
use nanoid::nanoid;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;

pub fn gen_row_id() -> String {
    nanoid!(6)
}

pub const DEFAULT_ROW_HEIGHT: i32 = 42;

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct GridBlockRevision {
    pub block_id: String,
    pub rows: Vec<Arc<RowRevision>>,
}

pub type FieldId = String;
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct RowRevision {
    pub id: String,
    pub block_id: String,
    /// cells contains key/value pairs.
    /// key: field id,
    /// value: CellMeta
    #[serde(with = "indexmap::serde_seq")]
    pub cells: IndexMap<FieldId, CellRevision>,
    pub height: i32,
    pub visibility: bool,
}

impl RowRevision {
    pub fn new(block_id: &str) -> Self {
        Self {
            id: gen_row_id(),
            block_id: block_id.to_owned(),
            cells: Default::default(),
            height: DEFAULT_ROW_HEIGHT,
            visibility: true,
        }
    }
}
#[derive(Debug, Clone, Default)]
pub struct RowMetaChangeset {
    pub row_id: String,
    pub height: Option<i32>,
    pub visibility: Option<bool>,
    pub cell_by_field_id: HashMap<FieldId, CellRevision>,
}

#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize)]
pub struct CellRevision {
    pub data: String,
}

impl CellRevision {
    pub fn new(data: String) -> Self {
        Self { data }
    }
}
