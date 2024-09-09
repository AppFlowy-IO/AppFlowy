use collab_database::rows::RowDetail;
use std::fmt::{Display, Formatter};

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

  #[pb(index = 4)]
  pub is_move_row: bool,
}

impl RowsChangePB {
  pub fn new() -> Self {
    Default::default()
  }
}
impl Display for RowsChangePB {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    let mut parts = Vec::new();

    // Conditionally add inserted rows if not empty
    if !self.inserted_rows.is_empty() {
      let inserted_rows = self
        .inserted_rows
        .iter()
        .map(|row| format!("{}:{:?}", row.row_meta.id, row.index))
        .collect::<Vec<String>>()
        .join(", ");
      parts.push(format!("Inserted rows: {}", inserted_rows));
    }

    // Conditionally add deleted rows if not empty
    if !self.deleted_rows.is_empty() {
      let deleted_rows = self.deleted_rows.join(", ");
      parts.push(format!("Deleted rows: {}", deleted_rows));
    }

    // Conditionally add updated rows if not empty
    if !self.updated_rows.is_empty() {
      let updated_rows = self
        .updated_rows
        .iter()
        .map(|row| row.row_id.to_string())
        .collect::<Vec<String>>()
        .join(", ");
      parts.push(format!("Updated rows: {}", updated_rows));
    }

    // Always add is_move_row
    parts.push(format!("is_move_row: {}", self.is_move_row));

    // Join the parts together and write them to the formatter
    f.write_str(&parts.join(", "))
  }
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
