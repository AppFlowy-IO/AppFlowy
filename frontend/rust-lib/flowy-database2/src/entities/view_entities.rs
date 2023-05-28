use flowy_derive::ProtoBuf;

use crate::entities::{InsertedRowPB, UpdatedRowPB};

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct RowsVisibilityChangePB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 5)]
  pub visible_rows: Vec<InsertedRowPB>,

  #[pb(index = 6)]
  pub invisible_rows: Vec<String>,
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct RowsChangePB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub inserted_rows: Vec<InsertedRowPB>,

  #[pb(index = 3)]
  pub deleted_rows: Vec<String>,

  #[pb(index = 4)]
  pub updated_rows: Vec<UpdatedRowPB>,
}

impl RowsChangePB {
  pub fn from_insert(view_id: String, inserted_row: InsertedRowPB) -> Self {
    Self {
      view_id,
      inserted_rows: vec![inserted_row],
      ..Default::default()
    }
  }

  pub fn from_delete(view_id: String, deleted_row: String) -> Self {
    Self {
      view_id,
      deleted_rows: vec![deleted_row],
      ..Default::default()
    }
  }

  pub fn from_update(view_id: String, updated_row: UpdatedRowPB) -> Self {
    Self {
      view_id,
      updated_rows: vec![updated_row],
      ..Default::default()
    }
  }

  pub fn from_move(
    view_id: String,
    deleted_rows: Vec<String>,
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
