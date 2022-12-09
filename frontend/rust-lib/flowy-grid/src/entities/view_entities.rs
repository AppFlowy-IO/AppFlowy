use crate::entities::{GridLayout, InsertedRowPB, UpdatedRowPB};
use flowy_derive::ProtoBuf;

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct GridRowsVisibilityChangesetPB {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 5)]
    pub visible_rows: Vec<InsertedRowPB>,

    #[pb(index = 6)]
    pub invisible_rows: Vec<String>,
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct GridViewRowsChangesetPB {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2)]
    pub inserted_rows: Vec<InsertedRowPB>,

    #[pb(index = 3)]
    pub deleted_rows: Vec<String>,

    #[pb(index = 4)]
    pub updated_rows: Vec<UpdatedRowPB>,
}

impl GridViewRowsChangesetPB {
    pub fn insert(view_id: String, inserted_rows: Vec<InsertedRowPB>) -> Self {
        Self {
            view_id,
            inserted_rows,
            ..Default::default()
        }
    }

    pub fn delete(block_id: &str, deleted_rows: Vec<String>) -> Self {
        Self {
            view_id: block_id.to_owned(),
            deleted_rows,
            ..Default::default()
        }
    }

    pub fn update(block_id: &str, updated_rows: Vec<UpdatedRowPB>) -> Self {
        Self {
            view_id: block_id.to_owned(),
            updated_rows,
            ..Default::default()
        }
    }
}
