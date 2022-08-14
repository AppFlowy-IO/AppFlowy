use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;
use flowy_grid_data_model::revision::RowRevision;
use std::sync::Arc;

/// [BlockPB] contains list of row ids. The rows here does not contain any data, just the id
/// of the row. Check out [RowPB] for more details.
///
///
/// A grid can have many rows. Rows are therefore grouped into Blocks in order to make
/// things more efficient.
///                                        |
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct BlockPB {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub rows: Vec<RowPB>,
}

impl BlockPB {
    pub fn new(block_id: &str, rows: Vec<RowPB>) -> Self {
        Self {
            id: block_id.to_owned(),
            rows,
        }
    }
}

/// [RowPB] Describes a row. Has the id of the parent Block. Has the metadata of the row.
#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct RowPB {
    #[pb(index = 1)]
    pub block_id: String,

    #[pb(index = 2)]
    pub id: String,

    #[pb(index = 3)]
    pub height: i32,
}

impl RowPB {
    pub fn row_id(&self) -> &str {
        &self.id
    }

    pub fn block_id(&self) -> &str {
        &self.block_id
    }
}

impl std::convert::From<&RowRevision> for RowPB {
    fn from(rev: &RowRevision) -> Self {
        Self {
            block_id: rev.block_id.clone(),
            id: rev.id.clone(),
            height: rev.height,
        }
    }
}

impl std::convert::From<&Arc<RowRevision>> for RowPB {
    fn from(rev: &Arc<RowRevision>) -> Self {
        Self {
            block_id: rev.block_id.clone(),
            id: rev.id.clone(),
            height: rev.height,
        }
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct OptionalRowPB {
    #[pb(index = 1, one_of)]
    pub row: Option<RowPB>,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedRowPB {
    #[pb(index = 1)]
    pub items: Vec<RowPB>,
}

impl std::convert::From<Vec<RowPB>> for RepeatedRowPB {
    fn from(items: Vec<RowPB>) -> Self {
        Self { items }
    }
}

/// [RepeatedBlockPB] contains list of [BlockPB]
#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedBlockPB {
    #[pb(index = 1)]
    pub items: Vec<BlockPB>,
}

impl std::convert::From<Vec<BlockPB>> for RepeatedBlockPB {
    fn from(items: Vec<BlockPB>) -> Self {
        Self { items }
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct InsertedRowPB {
    #[pb(index = 1)]
    pub row: RowPB,

    #[pb(index = 2, one_of)]
    pub index: Option<i32>,
}

impl std::convert::From<RowPB> for InsertedRowPB {
    fn from(row: RowPB) -> Self {
        Self { row, index: None }
    }
}

impl std::convert::From<&RowRevision> for InsertedRowPB {
    fn from(row: &RowRevision) -> Self {
        let row_order = RowPB::from(row);
        Self::from(row_order)
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct GridBlockChangesetPB {
    #[pb(index = 1)]
    pub block_id: String,

    #[pb(index = 2)]
    pub inserted_rows: Vec<InsertedRowPB>,

    #[pb(index = 3)]
    pub deleted_rows: Vec<String>,

    #[pb(index = 4)]
    pub updated_rows: Vec<RowPB>,

    #[pb(index = 5)]
    pub visible_rows: Vec<String>,

    #[pb(index = 6)]
    pub hide_rows: Vec<String>,
}
impl GridBlockChangesetPB {
    pub fn insert(block_id: String, inserted_rows: Vec<InsertedRowPB>) -> Self {
        Self {
            block_id,
            inserted_rows,
            ..Default::default()
        }
    }

    pub fn delete(block_id: &str, deleted_rows: Vec<String>) -> Self {
        Self {
            block_id: block_id.to_owned(),
            deleted_rows,
            ..Default::default()
        }
    }

    pub fn update(block_id: &str, updated_rows: Vec<RowPB>) -> Self {
        Self {
            block_id: block_id.to_owned(),
            updated_rows,
            ..Default::default()
        }
    }
}

/// [QueryBlocksPayloadPB] is used to query the data of the block that belongs to the grid whose
/// id is grid_id.
#[derive(ProtoBuf, Default)]
pub struct QueryBlocksPayloadPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub block_ids: Vec<String>,
}

pub struct QueryGridBlocksParams {
    pub grid_id: String,
    pub block_ids: Vec<String>,
}

impl TryInto<QueryGridBlocksParams> for QueryBlocksPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<QueryGridBlocksParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        Ok(QueryGridBlocksParams {
            grid_id: grid_id.0,
            block_ids: self.block_ids,
        })
    }
}
