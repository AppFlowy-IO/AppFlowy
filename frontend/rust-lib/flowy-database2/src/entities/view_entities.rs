use collab_database::rows::RowDetail;

use flowy_derive::ProtoBuf;

use crate::entities::{InsertedRowPB, RowMetaPB, UpdatedRowPB};

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
  pub inserted_rows: Vec<InsertedRowPB>,

  #[pb(index = 2)]
  pub deleted_rows: Vec<String>,

  #[pb(index = 3)]
  pub updated_rows: Vec<UpdatedRowPB>,
}

impl RowsChangePB {
  pub fn from_insert(inserted_row: InsertedRowPB) -> Self {
    Self {
      inserted_rows: vec![inserted_row],
      ..Default::default()
    }
  }

  pub fn from_delete(deleted_row: String) -> Self {
    Self {
      deleted_rows: vec![deleted_row],
      ..Default::default()
    }
  }

  pub fn from_update(updated_row: UpdatedRowPB) -> Self {
    Self {
      updated_rows: vec![updated_row],
      ..Default::default()
    }
  }

  pub fn from_move(deleted_rows: Vec<String>, inserted_rows: Vec<InsertedRowPB>) -> Self {
    Self {
      inserted_rows,
      deleted_rows,
      ..Default::default()
    }
  }

  pub fn is_empty(&self) -> bool {
    self.deleted_rows.is_empty() && self.inserted_rows.is_empty() && self.updated_rows.is_empty()
  }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct DidFetchRowPB {
  #[pb(index = 1)]
  pub row_id: String,

  #[pb(index = 2)]
  pub height: i32,

  #[pb(index = 3)]
  pub visibility: bool,

  #[pb(index = 4)]
  pub created_at: i64,

  #[pb(index = 5)]
  pub modified_at: i64,

  #[pb(index = 6)]
  pub meta: RowMetaPB,
}

impl From<RowDetail> for DidFetchRowPB {
  fn from(value: RowDetail) -> Self {
    Self {
      row_id: value.row.id.to_string(),
      height: value.row.height,
      visibility: value.row.visibility,
      created_at: value.row.created_at,
      modified_at: value.row.modified_at,
      meta: RowMetaPB::from(value),
    }
  }
}
