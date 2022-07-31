use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;
use flowy_grid_data_model::revision::RowRevision;
use std::sync::Arc;

/// [GridBlockPB] contains list of row ids. The rows here does not contain any data, just the id
/// of the row. Check out [GridRowPB] for more details.
///
///
/// A grid can have many rows. Rows are therefore grouped into Blocks in order to make
/// things more efficient.
///                                        |
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct GridBlockPB {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub rows: Vec<GridRowPB>,
}

impl GridBlockPB {
    pub fn new(block_id: &str, rows: Vec<GridRowPB>) -> Self {
        Self {
            id: block_id.to_owned(),
            rows,
        }
    }
}

/// [GridRowPB] Describes a row. Has the id of the parent Block. Has the metadata of the row.
#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct GridRowPB {
    #[pb(index = 1)]
    pub block_id: String,

    #[pb(index = 2)]
    pub id: String,

    #[pb(index = 3)]
    pub height: i32,
}

impl GridRowPB {
    pub fn row_id(&self) -> &str {
        &self.id
    }

    pub fn block_id(&self) -> &str {
        &self.block_id
    }
}

impl std::convert::From<&RowRevision> for GridRowPB {
    fn from(rev: &RowRevision) -> Self {
        Self {
            block_id: rev.block_id.clone(),
            id: rev.id.clone(),
            height: rev.height,
        }
    }
}

impl std::convert::From<&Arc<RowRevision>> for GridRowPB {
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
    pub row: Option<GridRowPB>,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedRowPB {
    #[pb(index = 1)]
    pub items: Vec<GridRowPB>,
}

impl std::convert::From<Vec<GridRowPB>> for RepeatedRowPB {
    fn from(items: Vec<GridRowPB>) -> Self {
        Self { items }
    }
}

/// [RepeatedGridBlockPB] contains list of [GridBlockPB]
#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedGridBlockPB {
    #[pb(index = 1)]
    pub items: Vec<GridBlockPB>,
}

impl std::convert::From<Vec<GridBlockPB>> for RepeatedGridBlockPB {
    fn from(items: Vec<GridBlockPB>) -> Self {
        Self { items }
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct InsertedRowPB {
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
pub struct UpdatedRowPB {
    #[pb(index = 1)]
    pub block_id: String,

    #[pb(index = 2)]
    pub row_id: String,

    #[pb(index = 3)]
    pub row: GridRowPB,
}

impl UpdatedRowPB {
    pub fn new(row_rev: &RowRevision, row: GridRowPB) -> Self {
        Self {
            row_id: row_rev.id.clone(),
            block_id: row_rev.block_id.clone(),
            row,
        }
    }
}

impl std::convert::From<GridRowPB> for InsertedRowPB {
    fn from(row_info: GridRowPB) -> Self {
        Self {
            row_id: row_info.id,
            block_id: row_info.block_id,
            height: row_info.height,
            index: None,
        }
    }
}

impl std::convert::From<&RowRevision> for InsertedRowPB {
    fn from(row: &RowRevision) -> Self {
        let row_order = GridRowPB::from(row);
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
    pub updated_rows: Vec<UpdatedRowPB>,

    #[pb(index = 5)]
    pub visible_rows: Vec<String>,

    #[pb(index = 6)]
    pub hide_rows: Vec<String>,
}
impl GridBlockChangesetPB {
    pub fn insert(block_id: &str, inserted_rows: Vec<InsertedRowPB>) -> Self {
        Self {
            block_id: block_id.to_owned(),
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

    pub fn update(block_id: &str, updated_rows: Vec<UpdatedRowPB>) -> Self {
        Self {
            block_id: block_id.to_owned(),
            updated_rows,
            ..Default::default()
        }
    }
}

/// [QueryGridBlocksPayloadPB] is used to query the data of the block that belongs to the grid whose
/// id is grid_id.
#[derive(ProtoBuf, Default)]
pub struct QueryGridBlocksPayloadPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub block_ids: Vec<String>,
}

pub struct QueryGridBlocksParams {
    pub grid_id: String,
    pub block_ids: Vec<String>,
}

impl TryInto<QueryGridBlocksParams> for QueryGridBlocksPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<QueryGridBlocksParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        Ok(QueryGridBlocksParams {
            grid_id: grid_id.0,
            block_ids: self.block_ids,
        })
    }
}
