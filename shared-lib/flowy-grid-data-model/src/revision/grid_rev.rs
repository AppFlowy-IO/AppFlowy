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
    pub fields: Vec<Arc<FieldRevision>>,
    pub blocks: Vec<Arc<GridBlockMetaRevision>>,

    #[cfg(feature = "filter")]
    #[serde(default)]
    pub setting: GridSettingRevision,

    #[cfg(not(feature = "filter"))]
    #[serde(default, skip)]
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

    pub fn from_build_context(grid_id: &str, context: BuildGridContext) -> Self {
        Self {
            grid_id: grid_id.to_owned(),
            fields: context.field_revs,
            blocks: context.blocks.into_iter().map(Arc::new).collect(),
            setting: Default::default(),
        }
    }
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct GridBlockMetaRevision {
    pub block_id: String,
    pub start_row_index: i32,
    pub row_count: i32,
}

impl GridBlockMetaRevision {
    pub fn len(&self) -> i32 {
        self.row_count
    }

    pub fn is_empty(&self) -> bool {
        self.row_count == 0
    }
}

impl GridBlockMetaRevision {
    pub fn new() -> Self {
        GridBlockMetaRevision {
            block_id: gen_block_id(),
            ..Default::default()
        }
    }
}

pub struct GridBlockMetaRevisionChangeset {
    pub block_id: String,
    pub start_row_index: Option<i32>,
    pub row_count: Option<i32>,
}

impl GridBlockMetaRevisionChangeset {
    pub fn from_row_count(block_id: &str, row_count: i32) -> Self {
        Self {
            block_id: block_id.to_string(),
            start_row_index: None,
            row_count: Some(row_count),
        }
    }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct GridBlockRevision {
    pub block_id: String,
    pub rows: Vec<Arc<RowRevision>>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize, Eq, PartialEq)]
pub struct FieldRevision {
    pub id: String,

    pub name: String,

    pub desc: String,

    #[serde(rename = "field_type")]
    pub field_type_rev: FieldTypeRevision,

    pub frozen: bool,

    pub visibility: bool,

    pub width: i32,

    /// type_options contains key/value pairs
    /// key: id of the FieldType
    /// value: type option data that can be parsed into specified TypeOptionStruct.
    /// For example, CheckboxTypeOption, MultiSelectTypeOption etc.
    #[serde(with = "indexmap::serde_seq")]
    pub type_options: IndexMap<String, String>,

    #[serde(default = "DEFAULT_IS_PRIMARY")]
    pub is_primary: bool,
}

impl AsRef<FieldRevision> for FieldRevision {
    fn as_ref(&self) -> &FieldRevision {
        self
    }
}

const DEFAULT_IS_PRIMARY: fn() -> bool = || false;

impl FieldRevision {
    pub fn new<T: Into<FieldTypeRevision>>(
        name: &str,
        desc: &str,
        field_type: T,
        width: i32,
        is_primary: bool,
    ) -> Self {
        Self {
            id: gen_field_id(),
            name: name.to_string(),
            desc: desc.to_string(),
            field_type_rev: field_type.into(),
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
        let id = self.field_type_rev.to_string();
        self.type_options.insert(id, entry.json_str());
    }

    pub fn get_type_option_entry<T: TypeOptionDataDeserializer>(&self, field_type_rev: FieldTypeRevision) -> Option<T> {
        let id = field_type_rev.to_string();
        self.type_options.get(&id).map(|s| T::from_json_str(s))
    }

    pub fn insert_type_option_str(&mut self, field_type: &FieldTypeRevision, json_str: String) {
        let id = field_type.to_string();
        self.type_options.insert(id, json_str);
    }

    pub fn get_type_option_str<T: Into<FieldTypeRevision>>(&self, field_type: T) -> Option<String> {
        let field_type_rev = field_type.into();
        let id = field_type_rev.to_string();
        self.type_options.get(&id).map(|s| s.to_owned())
    }
}

pub trait TypeOptionDataEntry {
    fn json_str(&self) -> String;
    fn protobuf_bytes(&self) -> Bytes;
}

pub trait TypeOptionDataDeserializer {
    fn from_json_str(s: &str) -> Self;
    fn from_protobuf_bytes(bytes: Bytes) -> Self;
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

#[derive(Clone, Default, Deserialize, Serialize)]
pub struct BuildGridContext {
    pub field_revs: Vec<Arc<FieldRevision>>,
    pub blocks: Vec<GridBlockMetaRevision>,
    pub blocks_meta_data: Vec<GridBlockRevision>,
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

pub type FieldTypeRevision = u8;
