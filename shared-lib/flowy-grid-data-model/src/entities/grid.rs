use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use strum_macros::{Display, EnumIter, EnumString};

pub trait GridIdentifiable {
    fn id(&self) -> &str;
}

#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize, ProtoBuf)]
pub struct Grid {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    #[serde(flatten)]
    pub field_orders: RepeatedFieldOrder,

    #[pb(index = 3)]
    #[serde(flatten)]
    pub row_orders: RepeatedRowOrder,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize, ProtoBuf)]
pub struct FieldOrder {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub visibility: bool,
}

impl std::convert::From<&Field> for FieldOrder {
    fn from(field: &Field) -> Self {
        Self {
            field_id: field.id.clone(),
            visibility: true,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize, ProtoBuf)]
pub struct RepeatedFieldOrder {
    #[pb(index = 1)]
    #[serde(rename(serialize = "field_orders", deserialize = "field_orders"))]
    pub items: Vec<FieldOrder>,
}

impl std::convert::From<Vec<FieldOrder>> for RepeatedFieldOrder {
    fn from(items: Vec<FieldOrder>) -> Self {
        Self { items }
    }
}

impl std::ops::Deref for RepeatedFieldOrder {
    type Target = Vec<FieldOrder>;

    fn deref(&self) -> &Self::Target {
        &self.items
    }
}

impl std::ops::DerefMut for RepeatedFieldOrder {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.items
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct Field {
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
    pub width: i32,

    #[pb(index = 7)]
    pub type_options: AnyData,
}

impl GridIdentifiable for Field {
    fn id(&self) -> &str {
        &self.id
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedField {
    #[pb(index = 1)]
    pub items: Vec<Field>,
}
impl std::ops::Deref for RepeatedField {
    type Target = Vec<Field>;
    fn deref(&self) -> &Self::Target {
        &self.items
    }
}

impl std::ops::DerefMut for RepeatedField {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.items
    }
}

impl std::convert::From<Vec<Field>> for RepeatedField {
    fn from(items: Vec<Field>) -> Self {
        Self { items }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum, EnumString, EnumIter, Display, Serialize, Deserialize)]
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

impl FieldType {
    #[allow(dead_code)]
    pub fn type_id(&self) -> String {
        let ty = self.clone();
        format!("{}", ty as u8)
    }

    pub fn from_type_id(type_id: &str) -> Result<FieldType, String> {
        match type_id {
            "0" => Ok(FieldType::RichText),
            "1" => Ok(FieldType::Number),
            "2" => Ok(FieldType::DateTime),
            "3" => Ok(FieldType::SingleSelect),
            "4" => Ok(FieldType::MultiSelect),
            "5" => Ok(FieldType::Checkbox),
            _ => Err(format!("Invalid type_id: {}", type_id)),
        }
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct AnyData {
    #[pb(index = 1)]
    pub type_id: String,

    #[pb(index = 2)]
    pub value: Vec<u8>,
}

impl AnyData {
    pub fn from_str(field_type: &FieldType, s: &str) -> AnyData {
        Self::from_bytes(field_type, s.as_bytes().to_vec())
    }

    pub fn from_bytes<T: AsRef<[u8]>>(field_type: &FieldType, bytes: T) -> AnyData {
        AnyData {
            type_id: field_type.type_id(),
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

#[derive(Debug, Default, Clone, PartialEq, Eq, Serialize, Deserialize, ProtoBuf)]
pub struct RowOrder {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub row_id: String,

    #[pb(index = 3)]
    pub visibility: bool,
}

impl std::convert::From<&RawRow> for RowOrder {
    fn from(row: &RawRow) -> Self {
        Self {
            grid_id: row.grid_id.clone(),
            row_id: row.id.clone(),
            visibility: true,
        }
    }
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize, ProtoBuf)]
pub struct RepeatedRowOrder {
    #[pb(index = 1)]
    #[serde(rename(serialize = "row_orders", deserialize = "row_orders"))]
    pub items: Vec<RowOrder>,
}

impl std::convert::From<Vec<RowOrder>> for RepeatedRowOrder {
    fn from(items: Vec<RowOrder>) -> Self {
        Self { items }
    }
}

impl std::ops::Deref for RepeatedRowOrder {
    type Target = Vec<RowOrder>;
    fn deref(&self) -> &Self::Target {
        &self.items
    }
}

impl std::ops::DerefMut for RepeatedRowOrder {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.items
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RawRow {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub grid_id: String,

    #[pb(index = 3)]
    pub cell_by_field_id: HashMap<String, RawCell>,
}

impl GridIdentifiable for RawRow {
    fn id(&self) -> &str {
        &self.id
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RawCell {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub row_id: String,

    #[pb(index = 3)]
    pub field_id: String,

    #[pb(index = 4)]
    pub data: AnyData,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedRow {
    #[pb(index = 1)]
    pub items: Vec<Row>,
}

impl std::ops::Deref for RepeatedRow {
    type Target = Vec<Row>;
    fn deref(&self) -> &Self::Target {
        &self.items
    }
}

impl std::ops::DerefMut for RepeatedRow {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.items
    }
}

impl std::convert::From<Vec<Row>> for RepeatedRow {
    fn from(items: Vec<Row>) -> Self {
        Self { items }
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct Row {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub cell_by_field_id: HashMap<String, Cell>,
}

impl Row {
    pub fn new(row_id: &str) -> Self {
        Self {
            id: row_id.to_owned(),
            cell_by_field_id: HashMap::new(),
        }
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct Cell {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub field_id: String,

    #[pb(index = 3)]
    pub content: String,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct CellChangeset {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub row_id: String,

    #[pb(index = 3)]
    pub field_id: String,

    #[pb(index = 4)]
    pub data: String,
}

#[derive(ProtoBuf, Default)]
pub struct CreateGridPayload {
    #[pb(index = 1)]
    pub name: String,
}

#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct GridId {
    #[pb(index = 1)]
    pub value: String,
}

impl AsRef<str> for GridId {
    fn as_ref(&self) -> &str {
        &self.value
    }
}

#[derive(ProtoBuf, Default)]
pub struct QueryFieldPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub field_orders: RepeatedFieldOrder,
}

#[derive(ProtoBuf, Default)]
pub struct QueryRowPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub row_orders: RepeatedRowOrder,
}
