use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use std::collections::HashMap;

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

    #[pb(index = 3)]
    pub width: i32,
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
    pub type_options: AnyData,
}

#[derive(Debug, ProtoBuf_Enum)]
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

#[derive(Debug, Default, ProtoBuf)]
pub struct AnyData {
    #[pb(index = 1)]
    pub type_url: String,

    #[pb(index = 2)]
    pub value: Vec<u8>,
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
pub struct Row {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub grid_id: String,

    #[pb(index = 3)]
    pub modified_time: i64,

    #[pb(index = 4)]
    pub cell_by_field_id: HashMap<String, Cell>,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct Cell {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub row_id: String,

    #[pb(index = 3)]
    pub field_id: String,

    #[pb(index = 4)]
    pub data: AnyData,
}
