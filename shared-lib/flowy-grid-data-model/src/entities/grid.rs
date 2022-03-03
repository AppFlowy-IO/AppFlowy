use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use std::collections::HashMap;

use strum_macros::{Display, EnumIter, EnumString};

#[derive(Debug, Default, ProtoBuf)]
pub struct Grid {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub filters: RepeatedGridFilter,

    #[pb(index = 3)]
    pub field_orders: RepeatedFieldOrder,

    #[pb(index = 4)]
    pub row_orders: RepeatedRowOrder,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct GridFilter {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub desc: String,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedGridFilter {
    #[pb(index = 1)]
    pub items: Vec<GridFilter>,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct FieldOrder {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub visibility: bool,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedFieldOrder {
    #[pb(index = 1)]
    pub items: Vec<FieldOrder>,
}

#[derive(Debug, Default, ProtoBuf)]
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

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedField {
    #[pb(index = 1)]
    pub items: Vec<Field>,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum, EnumString, EnumIter, Display)]
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

#[derive(Debug, Default, ProtoBuf)]
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

#[derive(Debug, Default, ProtoBuf)]
pub struct RowOrder {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub row_id: String,

    #[pb(index = 3)]
    pub visibility: bool,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedRowOrder {
    #[pb(index = 1)]
    pub items: Vec<RowOrder>,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct GridRow {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub grid_id: String,

    #[pb(index = 3)]
    pub modified_time: i64,

    #[pb(index = 4)]
    pub cell_by_field_id: HashMap<String, GridCell>,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedRow {
    #[pb(index = 1)]
    pub items: Vec<GridRow>,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct GridCell {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub row_id: String,

    #[pb(index = 3)]
    pub field_id: String,

    #[pb(index = 4)]
    pub content: String,
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
