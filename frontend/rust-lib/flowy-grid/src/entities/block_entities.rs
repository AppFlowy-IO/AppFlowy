use crate::entities::GridRowId;
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
    pub row_infos: Vec<BlockRowInfo>,
}

impl GridBlock {
    pub fn new(block_id: &str, row_orders: Vec<BlockRowInfo>) -> Self {
        Self {
            id: block_id.to_owned(),
            row_infos: row_orders,
        }
    }
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct BlockRowInfo {
    #[pb(index = 1)]
    pub block_id: String,

    #[pb(index = 2)]
    pub row_id: String,

    #[pb(index = 3)]
    pub height: i32,
}

impl BlockRowInfo {
    pub fn row_id(&self) -> &str {
        &self.row_id
    }

    pub fn block_id(&self) -> &str {
        &self.block_id
    }
}

impl std::convert::From<&RowRevision> for BlockRowInfo {
    fn from(rev: &RowRevision) -> Self {
        Self {
            block_id: rev.block_id.clone(),
            row_id: rev.id.clone(),
            height: rev.height,
        }
    }
}

impl std::convert::From<&Arc<RowRevision>> for BlockRowInfo {
    fn from(rev: &Arc<RowRevision>) -> Self {
        Self {
            block_id: rev.block_id.clone(),
            row_id: rev.id.clone(),
            height: rev.height,
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
pub struct InsertedRow {
    #[pb(index = 1)]
    pub block_id: String,

    #[pb(index = 2)]
    pub row_id: String,

    #[pb(index = 3)]
    pub height: i32,

    #[pb(index = 4, one_of)]
    pub index: Option<i32>,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct UpdatedRow {
    #[pb(index = 1)]
    pub block_id: String,

    #[pb(index = 2)]
    pub row_id: String,

    #[pb(index = 3)]
    pub row: Row,
}

impl UpdatedRow {
    pub fn new(row_rev: &RowRevision, row: Row) -> Self {
        Self {
            row_id: row_rev.id.clone(),
            block_id: row_rev.block_id.clone(),
            row,
        }
    }
}

impl std::convert::From<BlockRowInfo> for InsertedRow {
    fn from(row_info: BlockRowInfo) -> Self {
        Self {
            row_id: row_info.row_id,
            block_id: row_info.block_id,
            height: row_info.height,
            index: None,
        }
    }
}

impl std::convert::From<&RowRevision> for InsertedRow {
    fn from(row: &RowRevision) -> Self {
        let row_order = BlockRowInfo::from(row);
        Self::from(row_order)
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct GridBlockChangeset {
    #[pb(index = 1)]
    pub block_id: String,

    #[pb(index = 2)]
    pub inserted_rows: Vec<InsertedRow>,

    #[pb(index = 3)]
    pub deleted_rows: Vec<GridRowId>,

    #[pb(index = 4)]
    pub updated_rows: Vec<UpdatedRow>,
}
impl GridBlockChangeset {
    pub fn insert(block_id: &str, inserted_rows: Vec<InsertedRow>) -> Self {
        Self {
            block_id: block_id.to_owned(),
            inserted_rows,
            deleted_rows: vec![],
            updated_rows: vec![],
        }
    }

    pub fn delete(block_id: &str, deleted_rows: Vec<GridRowId>) -> Self {
        Self {
            block_id: block_id.to_owned(),
            inserted_rows: vec![],
            deleted_rows,
            updated_rows: vec![],
        }
    }

    pub fn update(block_id: &str, updated_rows: Vec<UpdatedRow>) -> Self {
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
