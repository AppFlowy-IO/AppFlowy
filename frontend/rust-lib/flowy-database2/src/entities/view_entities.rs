use flowy_derive::ProtoBuf;

use crate::entities::{InsertedRowPB, UpdatedRowPB};

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct RowsVisibilityChangesetPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 5)]
  pub visible_rows: Vec<InsertedRowPB>,

  #[pb(index = 6)]
  pub invisible_rows: Vec<i64>,
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct RowsChangesetPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub inserted_rows: Vec<InsertedRowPB>,

  #[pb(index = 3)]
  pub deleted_rows: Vec<i64>,

  #[pb(index = 4)]
  pub updated_rows: Vec<UpdatedRowPB>,
}

impl RowsChangesetPB {
  pub fn from_insert(view_id: String, inserted_rows: Vec<InsertedRowPB>) -> Self {
    Self {
      view_id,
      inserted_rows,
      ..Default::default()
    }
  }

  pub fn from_delete(view_id: String, deleted_rows: Vec<i64>) -> Self {
    Self {
      view_id,
      deleted_rows,
      ..Default::default()
    }
  }

  pub fn from_update(view_id: String, updated_rows: Vec<UpdatedRowPB>) -> Self {
    Self {
      view_id,
      updated_rows,
      ..Default::default()
    }
  }

  pub fn from_move(
    view_id: String,
    deleted_rows: Vec<i64>,
    inserted_rows: Vec<InsertedRowPB>,
  ) -> Self {
    Self {
      view_id,
      inserted_rows,
      deleted_rows,
      ..Default::default()
    }
  }
}
