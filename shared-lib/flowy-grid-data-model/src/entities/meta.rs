use crate::entities::Row;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use strum_macros::{Display, EnumIter, EnumString};

pub const DEFAULT_ROW_HEIGHT: i32 = 36;
pub const DEFAULT_FIELD_WIDTH: i32 = 150;

#[derive(Debug, Clone, Default, Serialize, Deserialize, ProtoBuf)]
pub struct GridMeta {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub fields: Vec<Field>,

    #[pb(index = 3)]
    pub rows: Vec<RowMeta>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize, ProtoBuf)]
pub struct GridBlock {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub rows: Vec<RowMeta>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize, ProtoBuf)]
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
    pub visibility: bool,

    #[pb(index = 7)]
    pub width: i32,

    #[pb(index = 8)]
    pub type_options: AnyData,
}

impl Field {
    pub fn new(id: &str, name: &str, desc: &str, field_type: FieldType) -> Self {
        Self {
            id: id.to_owned(),
            name: name.to_string(),
            desc: desc.to_string(),
            field_type,
            frozen: false,
            visibility: true,
            width: DEFAULT_FIELD_WIDTH,
            type_options: Default::default(),
        }
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

#[derive(Debug, Clone, Serialize, Deserialize, Default, ProtoBuf)]
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

#[derive(Debug, Clone, Default, Serialize, Deserialize, ProtoBuf)]
pub struct RowMeta {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub grid_id: String,

    #[pb(index = 3)]
    pub cell_by_field_id: HashMap<String, CellMeta>,

    #[pb(index = 4)]
    pub height: i32,

    #[pb(index = 5)]
    pub visibility: bool,
}

impl RowMeta {
    pub fn new(id: &str, grid_id: &str, cells: Vec<CellMeta>) -> Self {
        let cell_by_field_id = cells
            .into_iter()
            .map(|cell| (cell.id.clone(), cell))
            .collect::<HashMap<String, CellMeta>>();

        Self {
            id: id.to_owned(),
            grid_id: grid_id.to_owned(),
            cell_by_field_id,
            height: DEFAULT_ROW_HEIGHT,
            visibility: true,
        }
    }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize, ProtoBuf)]
pub struct CellMeta {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub row_id: String,

    #[pb(index = 3)]
    pub field_id: String,

    #[pb(index = 4)]
    pub data: AnyData,

    #[pb(index = 5)]
    pub height: i32,
}
