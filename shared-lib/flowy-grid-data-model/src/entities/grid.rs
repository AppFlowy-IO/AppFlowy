use crate::entities::FieldOrder;
use crate::parser::NotEmptyStr;
use crate::revision::RowRevision;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error_code::ErrorCode;

use std::collections::HashMap;

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct Grid {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub field_orders: Vec<FieldOrder>,

    #[pb(index = 3)]
    pub block_orders: Vec<GridBlockOrder>,
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct RowOrder {
    #[pb(index = 1)]
    pub row_id: String,

    #[pb(index = 2)]
    pub block_id: String,

    #[pb(index = 3)]
    pub height: i32,
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

impl std::convert::From<Vec<Row>> for RepeatedRow {
    fn from(items: Vec<Row>) -> Self {
        Self { items }
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedGridBlock {
    #[pb(index = 1)]
    pub items: Vec<GridBlock>,
}

impl std::convert::From<Vec<GridBlock>> for RepeatedGridBlock {
    fn from(items: Vec<GridBlock>) -> Self {
        Self { items }
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct GridBlockOrder {
    #[pb(index = 1)]
    pub block_id: String,

    #[pb(index = 2)]
    pub row_orders: Vec<RowOrder>,
}

impl GridBlockOrder {
    pub fn new(block_id: &str) -> Self {
        GridBlockOrder {
            block_id: block_id.to_owned(),
            row_orders: vec![],
        }
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct IndexRowOrder {
    #[pb(index = 1)]
    pub row_order: RowOrder,

    #[pb(index = 2, one_of)]
    pub index: Option<i32>,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct UpdatedRowOrder {
    #[pb(index = 1)]
    pub row_order: RowOrder,

    #[pb(index = 2)]
    pub row: Row,
}

impl UpdatedRowOrder {
    pub fn new(row_rev: &RowRevision, row: Row) -> Self {
        Self {
            row_order: RowOrder::from(row_rev),
            row,
        }
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct GridRowsChangeset {
    #[pb(index = 1)]
    pub block_id: String,

    #[pb(index = 2)]
    pub inserted_rows: Vec<IndexRowOrder>,

    #[pb(index = 3)]
    pub deleted_rows: Vec<RowOrder>,

    #[pb(index = 4)]
    pub updated_rows: Vec<UpdatedRowOrder>,
}

impl std::convert::From<RowOrder> for IndexRowOrder {
    fn from(row_order: RowOrder) -> Self {
        Self { row_order, index: None }
    }
}

impl std::convert::From<&RowRevision> for IndexRowOrder {
    fn from(row: &RowRevision) -> Self {
        let row_order = RowOrder::from(row);
        Self::from(row_order)
    }
}

impl GridRowsChangeset {
    pub fn insert(block_id: &str, inserted_rows: Vec<IndexRowOrder>) -> Self {
        Self {
            block_id: block_id.to_owned(),
            inserted_rows,
            deleted_rows: vec![],
            updated_rows: vec![],
        }
    }

    pub fn delete(block_id: &str, deleted_rows: Vec<RowOrder>) -> Self {
        Self {
            block_id: block_id.to_owned(),
            inserted_rows: vec![],
            deleted_rows,
            updated_rows: vec![],
        }
    }

    pub fn update(block_id: &str, updated_rows: Vec<UpdatedRowOrder>) -> Self {
        Self {
            block_id: block_id.to_owned(),
            inserted_rows: vec![],
            deleted_rows: vec![],
            updated_rows,
        }
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct GridBlock {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub row_orders: Vec<RowOrder>,
}

impl GridBlock {
    pub fn new(block_id: &str, row_orders: Vec<RowOrder>) -> Self {
        Self {
            id: block_id.to_owned(),
            row_orders,
        }
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct Cell {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub data: Vec<u8>,
}

impl Cell {
    pub fn new(field_id: &str, data: Vec<u8>) -> Self {
        Self {
            field_id: field_id.to_owned(),
            data,
        }
    }

    pub fn empty(field_id: &str) -> Self {
        Self {
            field_id: field_id.to_owned(),
            data: vec![],
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

#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct GridBlockId {
    #[pb(index = 1)]
    pub value: String,
}

impl AsRef<str> for GridBlockId {
    fn as_ref(&self) -> &str {
        &self.value
    }
}

impl std::convert::From<&str> for GridBlockId {
    fn from(s: &str) -> Self {
        GridBlockId { value: s.to_owned() }
    }
}

#[derive(ProtoBuf, Default)]
pub struct CreateRowPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2, one_of)]
    pub start_row_id: Option<String>,
}

#[derive(Default)]
pub struct CreateRowParams {
    pub grid_id: String,
    pub start_row_id: Option<String>,
}

impl TryInto<CreateRowParams> for CreateRowPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateRowParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        Ok(CreateRowParams {
            grid_id: grid_id.0,
            start_row_id: self.start_row_id,
        })
    }
}

#[derive(ProtoBuf, Default)]
pub struct QueryGridBlocksPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub block_orders: Vec<GridBlockOrder>,
}

pub struct QueryGridBlocksParams {
    pub grid_id: String,
    pub block_orders: Vec<GridBlockOrder>,
}

impl TryInto<QueryGridBlocksParams> for QueryGridBlocksPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<QueryGridBlocksParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        Ok(QueryGridBlocksParams {
            grid_id: grid_id.0,
            block_orders: self.block_orders,
        })
    }
}

#[derive(Debug, Clone, ProtoBuf_Enum)]
pub enum MoveItemType {
    MoveField = 0,
    MoveRow = 1,
}

impl std::default::Default for MoveItemType {
    fn default() -> Self {
        MoveItemType::MoveField
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct MoveItemPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub item_id: String,

    #[pb(index = 3)]
    pub from_index: i32,

    #[pb(index = 4)]
    pub to_index: i32,

    #[pb(index = 5)]
    pub ty: MoveItemType,
}

#[derive(Clone)]
pub struct MoveItemParams {
    pub grid_id: String,
    pub item_id: String,
    pub from_index: i32,
    pub to_index: i32,
    pub ty: MoveItemType,
}

impl TryInto<MoveItemParams> for MoveItemPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<MoveItemParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let item_id = NotEmptyStr::parse(self.item_id).map_err(|_| ErrorCode::InvalidData)?;
        Ok(MoveItemParams {
            grid_id: grid_id.0,
            item_id: item_id.0,
            from_index: self.from_index,
            to_index: self.to_index,
            ty: self.ty,
        })
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct CellChangeset {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub row_id: String,

    #[pb(index = 3)]
    pub field_id: String,

    #[pb(index = 4, one_of)]
    pub cell_content_changeset: Option<String>,
}
