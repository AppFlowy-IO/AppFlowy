use collab_database::rows::{RowDetail, RowId};
use collab_database::views::DatabaseLayout;

#[derive(Debug, Clone)]
pub enum DatabaseRowEvent {
  InsertRow(InsertedRow),
  UpdateRow(UpdatedRow),
  DeleteRow(RowId),
  Move {
    deleted_row_id: RowId,
    inserted_row: InsertedRow,
  },
}

#[derive(Debug, Clone)]
pub struct InsertedRow {
  pub row_detail: RowDetail,
  pub index: Option<i32>,
  pub is_new: bool,
}

#[derive(Debug, Clone)]
pub struct UpdatedRow {
  pub row_id: String,

  pub height: Option<i32>,

  /// Indicates which cells were updated.
  pub field_ids: Vec<String>,

  /// The meta of row was updated if this is Some.
  pub row_detail: Option<RowDetail>,
}

impl UpdatedRow {
  pub fn new(row_id: &str) -> Self {
    Self {
      row_id: row_id.to_string(),
      height: None,
      field_ids: vec![],
      row_detail: None,
    }
  }

  pub fn with_field_ids(mut self, field_ids: Vec<String>) -> Self {
    self.field_ids = field_ids;
    self
  }

  pub fn with_height(mut self, height: i32) -> Self {
    self.height = Some(height);
    self
  }

  pub fn with_row_meta(mut self, row_detail: RowDetail) -> Self {
    self.row_detail = Some(row_detail);
    self
  }
}

#[derive(Debug, Clone)]
pub struct CreateDatabaseViewParams {
  pub name: String,
  pub view_id: String,
  pub layout_type: DatabaseLayout,
}

pub enum DatabaseRowState {
  Initialized,
  Uninitialized,
}

impl DatabaseRowState {
  pub fn is_initialized(&self) -> bool {
    matches!(self, DatabaseRowState::Initialized)
  }
}
