use crate::entities::{FieldMeta, FieldType, RowMeta};
use flowy_derive::ProtoBuf;
use std::collections::HashMap;
use std::sync::Arc;

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
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct FieldOrder {
    #[pb(index = 1)]
    pub field_id: String,
}

impl std::convert::From<&FieldMeta> for FieldOrder {
    fn from(field_meta: &FieldMeta) -> Self {
        Self {
            field_id: field_meta.id.clone(),
        }
    }
}

impl std::convert::From<FieldMeta> for Field {
    fn from(field_meta: FieldMeta) -> Self {
        Self {
            id: field_meta.id,
            name: field_meta.name,
            desc: field_meta.desc,
            field_type: field_meta.field_type,
            frozen: field_meta.frozen,
            visibility: field_meta.visibility,
            width: field_meta.width,
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

impl std::convert::From<&Arc<RowMeta>> for RowOrder {
    fn from(row: &Arc<RowMeta>) -> Self {
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

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedCell {
    #[pb(index = 1)]
    pub items: Vec<Cell>,
}

impl std::ops::Deref for RepeatedCell {
    type Target = Vec<Cell>;
    fn deref(&self) -> &Self::Target {
        &self.items
    }
}

impl std::ops::DerefMut for RepeatedCell {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.items
    }
}

impl std::convert::From<Vec<Cell>> for RepeatedCell {
    fn from(items: Vec<Cell>) -> Self {
        Self { items }
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
pub struct CreateRowPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2, one_of)]
    pub upper_row_id: Option<String>,
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
