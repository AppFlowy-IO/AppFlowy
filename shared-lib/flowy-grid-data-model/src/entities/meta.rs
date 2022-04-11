use crate::entities::FieldType;
use bytes::Bytes;
use indexmap::IndexMap;
use nanoid::nanoid;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

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
pub struct GridMeta {
    pub grid_id: String,
    pub fields: Vec<FieldMeta>,
    pub blocks: Vec<GridBlockMeta>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct GridBlockMeta {
    pub block_id: String,
    pub start_row_index: i32,
    pub row_count: i32,
}

impl GridBlockMeta {
    pub fn len(&self) -> i32 {
        self.row_count
    }

    pub fn is_empty(&self) -> bool {
        self.row_count == 0
    }
}

impl GridBlockMeta {
    pub fn new() -> Self {
        GridBlockMeta {
            block_id: gen_block_id(),
            ..Default::default()
        }
    }
}

pub struct GridBlockMetaChangeset {
    pub block_id: String,
    pub start_row_index: Option<i32>,
    pub row_count: Option<i32>,
}

impl GridBlockMetaChangeset {
    pub fn from_row_count(block_id: &str, row_count: i32) -> Self {
        Self {
            block_id: block_id.to_string(),
            start_row_index: None,
            row_count: Some(row_count),
        }
    }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct GridBlockMetaData {
    pub block_id: String,
    pub rows: Vec<RowMeta>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize, Eq, PartialEq)]
pub struct FieldMeta {
    pub id: String,

    pub name: String,

    pub desc: String,

    pub field_type: FieldType,

    pub frozen: bool,

    pub visibility: bool,

    pub width: i32,

    // #[pb(index = 8)]
    /// type_options contains key/value pairs
    /// key: id of the FieldType
    /// value: type option data string
    #[serde(with = "indexmap::serde_seq")]
    pub type_options: IndexMap<String, String>,
}

impl FieldMeta {
    pub fn new(name: &str, desc: &str, field_type: FieldType) -> Self {
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

    pub fn get_type_option_str(&self, field_type: Option<FieldType>) -> Option<String> {
        let field_type = field_type.as_ref().unwrap_or(&self.field_type);
        self.type_options.get(&field_type.type_id()).map(|s| s.to_owned())
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
pub struct RowMeta {
    pub id: String,
    pub block_id: String,
    /// cells contains key/value pairs.
    /// key: field id,
    /// value: CellMeta
    #[serde(with = "indexmap::serde_seq")]
    pub cells: IndexMap<String, CellMeta>,
    pub height: i32,
    pub visibility: bool,
}

impl RowMeta {
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
    pub cell_by_field_id: HashMap<String, CellMeta>,
}

#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize)]
pub struct CellMeta {
    pub data: String,
}

impl CellMeta {
    pub fn new(data: String) -> Self {
        Self { data }
    }
}

#[derive(Clone, Deserialize, Serialize)]
pub struct BuildGridContext {
    pub field_metas: Vec<FieldMeta>,
    pub block_meta: GridBlockMeta,
    pub block_meta_data: GridBlockMetaData,
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

impl std::default::Default for BuildGridContext {
    fn default() -> Self {
        let block_meta = GridBlockMeta::new();
        let block_meta_data = GridBlockMetaData {
            block_id: block_meta.block_id.clone(),
            rows: vec![],
        };

        Self {
            field_metas: vec![],
            block_meta,
            block_meta_data,
        }
    }
}
