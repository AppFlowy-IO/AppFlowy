use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;
use flowy_grid_data_model::revision::RowRevision;
use std::sync::Arc;

#[derive(Debug, Clone, Default, ProtoBuf)]
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

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct RowOrder {
    #[pb(index = 1)]
    pub row_id: String,

    #[pb(index = 2)]
    pub block_id: String,

    #[pb(index = 3)]
    pub height: i32,
}

impl std::convert::From<&RowRevision> for RowOrder {
    fn from(row: &RowRevision) -> Self {
        Self {
            row_id: row.id.clone(),
            block_id: row.block_id.clone(),
            height: row.height,
        }
    }
}

impl std::convert::From<&Arc<RowRevision>> for RowOrder {
    fn from(row: &Arc<RowRevision>) -> Self {
        Self {
            row_id: row.id.clone(),
            block_id: row.block_id.clone(),
            height: row.height,
        }
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct Row {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub height: i32,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct OptionalRow {
    #[pb(index = 1, one_of)]
    pub row: Option<Row>,
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

#[derive(ProtoBuf, Default)]
pub struct GridBlockNotification {
    #[pb(index = 1)]
    hide_rows: Vec<String>,
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

#[derive(ProtoBuf, Default)]
pub struct QueryGridBlocksPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub block_ids: Vec<String>,
}

pub struct QueryGridBlocksParams {
    pub grid_id: String,
    pub block_ids: Vec<String>,
}

impl TryInto<QueryGridBlocksParams> for QueryGridBlocksPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<QueryGridBlocksParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        Ok(QueryGridBlocksParams {
            grid_id: grid_id.0,
            block_ids: self.block_ids,
        })
    }
}
