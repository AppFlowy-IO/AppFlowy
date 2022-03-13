use crate::entities::{Field, RowMeta};
use flowy_derive::ProtoBuf;
use std::collections::HashMap;

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct Grid {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub field_orders: Vec<FieldOrder>,

    #[pb(index = 3)]
    pub row_orders: Vec<RowOrder>,
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct FieldOrder {
    #[pb(index = 1)]
    pub field_id: String,
}

impl std::convert::From<&Field> for FieldOrder {
    fn from(field: &Field) -> Self {
        Self {
            field_id: field.id.clone(),
        }
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RepeatedFieldOrder {
    #[pb(index = 1)]
    pub items: Vec<FieldOrder>,
}

impl std::ops::Deref for RepeatedFieldOrder {
    type Target = Vec<FieldOrder>;
    fn deref(&self) -> &Self::Target {
        &self.items
    }
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct RowOrder {
    #[pb(index = 1)]
    pub row_id: String,

    #[pb(index = 2)]
    pub block_id: String,
}

impl std::convert::From<&RowMeta> for RowOrder {
    fn from(row: &RowMeta) -> Self {
        Self {
            row_id: row.id.clone(),
            block_id: row.block_id.clone(),
        }
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RepeatedRowOrder {
    #[pb(index = 1)]
    pub items: Vec<RowOrder>,
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
pub struct Row {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub cell_by_field_id: HashMap<String, Cell>,

    #[pb(index = 3)]
    pub height: i32,
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
pub struct Cell {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub content: String,
}

impl Cell {
    pub fn new(field_id: &str, content: String) -> Self {
        Self {
            field_id: field_id.to_owned(),
            content,
        }
    }
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
