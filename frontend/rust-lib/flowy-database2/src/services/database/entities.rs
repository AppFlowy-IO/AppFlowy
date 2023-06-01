use collab_database::rows::RowId;
use collab_database::views::{DatabaseLayout, RowOrder};

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
  pub row: RowOrder,
  pub index: Option<i32>,
  pub is_new: bool,
}

#[derive(Debug, Clone)]
pub struct UpdatedRow {
  pub row: RowOrder,
  // represents as the cells that were updated in this row.
  pub field_ids: Vec<String>,
}

#[derive(Debug, Clone)]
pub struct CreateDatabaseViewParams {
  pub name: String,
  pub view_id: String,
  pub layout_type: DatabaseLayout,
}
