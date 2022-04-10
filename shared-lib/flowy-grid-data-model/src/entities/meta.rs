use crate::parser::NotEmptyUuid;
use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error_code::ErrorCode;
use serde::{Deserialize, Serialize};
use serde_repr::*;
use std::collections::HashMap;
use strum_macros::{Display, EnumCount as EnumCountMacro, EnumIter, EnumString};

pub const DEFAULT_ROW_HEIGHT: i32 = 42;

#[derive(Debug, Clone, Default, Serialize, Deserialize, ProtoBuf)]
pub struct GridMeta {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub fields: Vec<FieldMeta>,

    #[pb(index = 3)]
    pub blocks: Vec<GridBlockMeta>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize, ProtoBuf)]
pub struct GridBlockMeta {
    #[pb(index = 1)]
    pub block_id: String,

    #[pb(index = 2)]
    pub start_row_index: i32,

    #[pb(index = 3)]
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
            block_id: uuid::Uuid::new_v4().to_string(),
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

#[derive(Debug, Clone, Default, Serialize, Deserialize, ProtoBuf)]
pub struct GridBlockMetaData {
    #[pb(index = 1)]
    pub block_id: String,

    #[pb(index = 2)]
    pub rows: Vec<RowMeta>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize, ProtoBuf, Eq, PartialEq)]
pub struct FieldMeta {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub desc: String,

    #[pb(index = 4)]
    pub field_type: FieldType,

    #[pb(index = 5)]
    pub frozen: bool,

    #[pb(index = 6)]
    pub visibility: bool,

    #[pb(index = 7)]
    pub width: i32,

    #[pb(index = 8)]
    /// type_options contains key/value pairs
    /// key: id of the FieldType
    /// value: type option data string
    pub type_options: HashMap<String, String>,
}

impl FieldMeta {
    pub fn new(name: &str, desc: &str, field_type: FieldType) -> Self {
        let width = field_type.default_cell_width();
        Self {
            id: uuid::Uuid::new_v4().to_string(),
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

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct FieldChangesetPayload {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub grid_id: String,

    #[pb(index = 3, one_of)]
    pub name: Option<String>,

    #[pb(index = 4, one_of)]
    pub desc: Option<String>,

    #[pb(index = 5, one_of)]
    pub field_type: Option<FieldType>,

    #[pb(index = 6, one_of)]
    pub frozen: Option<bool>,

    #[pb(index = 7, one_of)]
    pub visibility: Option<bool>,

    #[pb(index = 8, one_of)]
    pub width: Option<i32>,

    #[pb(index = 9, one_of)]
    pub type_option_data: Option<Vec<u8>>,
}

#[derive(Debug, Clone, Default)]
pub struct FieldChangesetParams {
    pub field_id: String,
    pub grid_id: String,
    pub name: Option<String>,
    pub desc: Option<String>,
    pub field_type: Option<FieldType>,
    pub frozen: Option<bool>,
    pub visibility: Option<bool>,
    pub width: Option<i32>,
    pub type_option_data: Option<Vec<u8>>,
}

impl TryInto<FieldChangesetParams> for FieldChangesetPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<FieldChangesetParams, Self::Error> {
        let grid_id = NotEmptyUuid::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let field_id = NotEmptyUuid::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;

        if let Some(type_option_data) = self.type_option_data.as_ref() {
            if type_option_data.is_empty() {
                return Err(ErrorCode::TypeOptionDataIsEmpty);
            }
        }

        Ok(FieldChangesetParams {
            field_id: field_id.0,
            grid_id: grid_id.0,
            name: self.name,
            desc: self.desc,
            field_type: self.field_type,
            frozen: self.frozen,
            visibility: self.visibility,
            width: self.width,
            type_option_data: self.type_option_data,
        })
    }
}

#[derive(
    Debug,
    Clone,
    PartialEq,
    Eq,
    ProtoBuf_Enum,
    EnumCountMacro,
    EnumString,
    EnumIter,
    Display,
    Serialize_repr,
    Deserialize_repr,
)]
#[repr(u8)]
pub enum FieldType {
    RichText = 0,
    Number = 1,
    DateTime = 2,
    SingleSelect = 3,
    MultiSelect = 4,
    Checkbox = 5,
}

impl std::default::Default for FieldType {
    fn default() -> Self {
        FieldType::RichText
    }
}

impl AsRef<FieldType> for FieldType {
    fn as_ref(&self) -> &FieldType {
        self
    }
}

impl From<&FieldType> for FieldType {
    fn from(field_type: &FieldType) -> Self {
        field_type.clone()
    }
}

impl FieldType {
    pub fn type_id(&self) -> String {
        let ty = self.clone();
        format!("{}", ty as u8)
    }

    pub fn default_cell_width(&self) -> i32 {
        match self {
            FieldType::DateTime => 180,
            _ => 150,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, ProtoBuf)]
pub struct AnyData {
    #[pb(index = 1)]
    pub type_id: String,

    #[pb(index = 2)]
    pub value: Vec<u8>,
}

impl AnyData {
    pub fn from_str<F: Into<FieldType>>(field_type: F, s: &str) -> AnyData {
        Self::from_bytes(field_type, s.as_bytes().to_vec())
    }

    pub fn from_bytes<T: AsRef<[u8]>, F: Into<FieldType>>(field_type: F, bytes: T) -> AnyData {
        AnyData {
            type_id: field_type.into().type_id(),
            value: bytes.as_ref().to_vec(),
        }
    }
}

impl ToString for AnyData {
    fn to_string(&self) -> String {
        match String::from_utf8(self.value.clone()) {
            Ok(s) => s,
            Err(_) => "".to_owned(),
        }
    }
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize, ProtoBuf)]
pub struct RowMeta {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub block_id: String,

    #[pb(index = 3)]
    /// cells contains key/value pairs.
    /// key: field id,
    /// value: CellMeta
    pub cells: HashMap<String, CellMeta>,

    #[pb(index = 4)]
    pub height: i32,

    #[pb(index = 5)]
    pub visibility: bool,
}

impl RowMeta {
    pub fn new(block_id: &str) -> Self {
        Self {
            id: uuid::Uuid::new_v4().to_string(),
            block_id: block_id.to_owned(),
            cells: Default::default(),
            height: DEFAULT_ROW_HEIGHT,
            visibility: true,
        }
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RowMetaChangeset {
    #[pb(index = 1)]
    pub row_id: String,

    #[pb(index = 2, one_of)]
    pub height: Option<i32>,

    #[pb(index = 3, one_of)]
    pub visibility: Option<bool>,

    #[pb(index = 4)]
    pub cell_by_field_id: HashMap<String, CellMeta>,
}

#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize, ProtoBuf)]
pub struct CellMeta {
    #[pb(index = 1)]
    pub data: String,
}

impl CellMeta {
    pub fn new(data: String) -> Self {
        Self { data }
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct CellMetaChangeset {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub row_id: String,

    #[pb(index = 3)]
    pub field_id: String,

    #[pb(index = 4, one_of)]
    pub data: Option<String>,
}

impl std::convert::From<CellMetaChangeset> for RowMetaChangeset {
    fn from(changeset: CellMetaChangeset) -> Self {
        let mut cell_by_field_id = HashMap::with_capacity(1);
        let field_id = changeset.field_id;
        let cell_meta = CellMeta {
            data: changeset.data.unwrap_or_else(|| "".to_owned()),
        };
        cell_by_field_id.insert(field_id, cell_meta);

        RowMetaChangeset {
            row_id: changeset.row_id,
            height: None,
            visibility: None,
            cell_by_field_id,
        }
    }
}

#[derive(Clone, ProtoBuf)]
pub struct BuildGridContext {
    #[pb(index = 1)]
    pub field_metas: Vec<FieldMeta>,

    #[pb(index = 2)]
    pub block_meta: GridBlockMeta,

    #[pb(index = 3)]
    pub block_meta_data: GridBlockMetaData,
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
