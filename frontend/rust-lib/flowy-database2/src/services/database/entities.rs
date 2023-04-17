use collab_database::views::RowOrder;

#[derive(Debug, Clone)]
pub enum DatabaseRowEvent {
  InsertRow(InsertedRow),
  UpdateRow(UpdatedRow),
  DeleteRow(i64),
  Move {
    deleted_row_id: i64,
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
