use crate::entities::{CellChangeset, Field, FieldOrder, FieldType, RowOrder};
use crate::revision::GridSettingRevision;
use bytes::Bytes;
use indexmap::IndexMap;
use nanoid::nanoid;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;

pub const DEFAULT_ROW_HEIGHT: i32 = 42;

pub fn gen_grid_id() -> String {
    // nanoid calculator https://zelark.github.io/nano-id-cc/
    nanoid!(10)
}

pub fn gen_block_id() -> String {
    nanoid!(10)
}

pub fn gen_row_id() -> String {
    nanoid!(6)
}

pub fn gen_field_id() -> String {
    nanoid!(6)
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct GridRevision {
    pub grid_id: String,
    pub fields: Vec<FieldRevision>,
    pub blocks: Vec<GridBlockRevision>,
    pub setting: GridSettingRevision,
}

impl GridRevision {
    pub fn new(grid_id: &str) -> Self {
        Self {
            grid_id: grid_id.to_owned(),
            fields: vec![],
            blocks: vec![],
            setting: GridSettingRevision::default(),
        }
    }
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct GridBlockRevision {
    pub block_id: String,
    pub start_row_index: i32,
    pub row_count: i32,
}

impl GridBlockRevision {
    pub fn len(&self) -> i32 {
        self.row_count
    }

    pub fn is_empty(&self) -> bool {
        self.row_count == 0
    }
}

impl GridBlockRevision {
    pub fn new() -> Self {
        GridBlockRevision {
            block_id: gen_block_id(),
            ..Default::default()
        }
    }
}

pub struct GridBlockRevisionChangeset {
    pub block_id: String,
    pub start_row_index: Option<i32>,
    pub row_count: Option<i32>,
}

impl GridBlockRevisionChangeset {
    pub fn from_row_count(block_id: &str, row_count: i32) -> Self {
        Self {
            block_id: block_id.to_string(),
            start_row_index: None,
            row_count: Some(row_count),
        }
    }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct GridBlockRevisionData {
    pub block_id: String,
    pub rows: Vec<RowRevision>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize, Eq, PartialEq)]
pub struct FieldRevision {
    pub id: String,

    pub name: String,

    pub desc: String,

    pub field_type: FieldType,

    pub frozen: bool,

    pub visibility: bool,

    pub width: i32,

    /// type_options contains key/value pairs
    /// key: id of the FieldType
    /// value: type option data that can be parsed into specified TypeOptionStruct.
    /// For example, CheckboxTypeOption, MultiSelectTypeOption etc.
    #[serde(with = "indexmap::serde_seq")]
    pub type_options: IndexMap<String, String>,

    #[serde(default = "default_is_primary")]
    pub is_primary: bool,
}

fn default_is_primary() -> bool {
    false
}

impl FieldRevision {
    pub fn new(name: &str, desc: &str, field_type: FieldType, is_primary: bool) -> Self {
        let width = field_type.default_cell_width();
        Self {
            id: gen_field_id(),
            name: name.to_string(),
            desc: desc.to_string(),
            field_type,
            frozen: false,
            visibility: true,
            width,
            type_options: Default::default(),
            is_primary,
        }
    }

    pub fn insert_type_option_entry<T>(&mut self, entry: &T)
    where
        T: TypeOptionDataEntry + ?Sized,
    {
        self.type_options.insert(entry.field_type().type_id(), entry.json_str());
    }

    pub fn get_type_option_entry<T: TypeOptionDataDeserializer>(&self, field_type: &FieldType) -> Option<T> {
        self.type_options
            .get(&field_type.type_id())
            .map(|s| T::from_json_str(s))
    }

    pub fn insert_type_option_str(&mut self, field_type: &FieldType, json_str: String) {
        self.type_options.insert(field_type.type_id(), json_str);
    }

    pub fn get_type_option_str(&self, field_type: &FieldType) -> Option<String> {
        self.type_options.get(&field_type.type_id()).map(|s| s.to_owned())
    }
}

impl std::convert::From<FieldRevision> for Field {
    fn from(field_rev: FieldRevision) -> Self {
        Self {
            id: field_rev.id,
            name: field_rev.name,
            desc: field_rev.desc,
            field_type: field_rev.field_type,
            frozen: field_rev.frozen,
            visibility: field_rev.visibility,
            width: field_rev.width,
            is_primary: field_rev.is_primary,
        }
    }
}

impl std::convert::From<&FieldRevision> for FieldOrder {
    fn from(field_rev: &FieldRevision) -> Self {
        Self {
            field_id: field_rev.id.clone(),
        }
    }
}

pub trait TypeOptionDataEntry {
    fn field_type(&self) -> FieldType;
    fn json_str(&self) -> String;
    fn protobuf_bytes(&self) -> Bytes;
}

pub trait TypeOptionDataDeserializer {
    fn from_json_str(s: &str) -> Self;
    fn from_protobuf_bytes(bytes: Bytes) -> Self;
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct RowRevision {
    pub id: String,
    pub block_id: String,
    /// cells contains key/value pairs.
    /// key: field id,
    /// value: CellMeta
    #[serde(with = "indexmap::serde_seq")]
    pub cells: IndexMap<String, CellRevision>,
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

impl std::convert::From<&RowRevision> for RowOrder {
    fn from(row: &RowRevision) -> Self {
        Self {
            row_id: row.id.clone(),
            block_id: row.block_id.clone(),
            height: row.height,
        }
    }
}

impl std::convert::From<&Arc<RowRevision>> for RowOrder {
    fn from(row: &Arc<RowRevision>) -> Self {
        Self {
            row_id: row.id.clone(),
            block_id: row.block_id.clone(),
            height: row.height,
        }
    }
}

#[derive(Debug, Clone, Default)]
pub struct RowMetaChangeset {
    pub row_id: String,
    pub height: Option<i32>,
    pub visibility: Option<bool>,
    pub cell_by_field_id: HashMap<String, CellRevision>,
}

impl std::convert::From<CellChangeset> for RowMetaChangeset {
    fn from(changeset: CellChangeset) -> Self {
        let mut cell_by_field_id = HashMap::with_capacity(1);
        let field_id = changeset.field_id;
        let cell_rev = CellRevision {
            data: changeset.cell_content_changeset.unwrap_or_else(|| "".to_owned()),
        };
        cell_by_field_id.insert(field_id, cell_rev);

        RowMetaChangeset {
            row_id: changeset.row_id,
            height: None,
            visibility: None,
            cell_by_field_id,
        }
    }
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

#[derive(Clone, Default, Deserialize, Serialize)]
pub struct BuildGridContext {
    pub field_revs: Vec<FieldRevision>,
    pub blocks: Vec<GridBlockRevision>,
    pub blocks_meta_data: Vec<GridBlockRevisionData>,
}

impl BuildGridContext {
    pub fn new() -> Self {
        Self::default()
    }
}

impl std::convert::From<BuildGridContext> for Bytes {
    fn from(ctx: BuildGridContext) -> Self {
        let bytes = serde_json::to_vec(&ctx).unwrap_or_else(|_| vec![]);
        Bytes::from(bytes)
    }
}

impl std::convert::TryFrom<Bytes> for BuildGridContext {
    type Error = serde_json::Error;

    fn try_from(bytes: Bytes) -> Result<Self, Self::Error> {
        let ctx: BuildGridContext = serde_json::from_slice(&bytes)?;
        Ok(ctx)
    }
}
