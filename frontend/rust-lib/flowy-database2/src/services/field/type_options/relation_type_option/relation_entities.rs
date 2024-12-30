use collab_database::rows::RowId;

#[derive(Debug, Clone, Default)]
pub struct RelationCellChangeset {
  pub inserted_row_ids: Vec<RowId>,
  pub removed_row_ids: Vec<RowId>,
}
