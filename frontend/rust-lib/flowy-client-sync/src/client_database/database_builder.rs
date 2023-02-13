use crate::errors::{SyncError, SyncResult};
use grid_model::{
  BuildDatabaseContext, DatabaseBlockRevision, FieldRevision, GridBlockMetaRevision, RowRevision,
};
use std::sync::Arc;

pub struct DatabaseBuilder {
  build_context: BuildDatabaseContext,
}

impl std::default::Default for DatabaseBuilder {
  fn default() -> Self {
    let mut build_context = BuildDatabaseContext::new();

    let block_meta = GridBlockMetaRevision::new();
    let block_meta_data = DatabaseBlockRevision {
      block_id: block_meta.block_id.clone(),
      rows: vec![],
    };

    build_context.block_metas.push(block_meta);
    build_context.blocks.push(block_meta_data);

    DatabaseBuilder { build_context }
  }
}

impl DatabaseBuilder {
  pub fn new() -> Self {
    Self::default()
  }
  pub fn add_field(&mut self, field: FieldRevision) {
    self.build_context.field_revs.push(Arc::new(field));
  }

  pub fn add_row(&mut self, row_rev: RowRevision) {
    let block_meta_rev = self.build_context.block_metas.first_mut().unwrap();
    let block_rev = self.build_context.blocks.first_mut().unwrap();
    block_rev.rows.push(Arc::new(row_rev));
    block_meta_rev.row_count += 1;
  }

  pub fn add_empty_row(&mut self) {
    let row = RowRevision::new(self.block_id());
    self.add_row(row);
  }

  pub fn field_revs(&self) -> &Vec<Arc<FieldRevision>> {
    &self.build_context.field_revs
  }

  pub fn block_id(&self) -> &str {
    &self.build_context.block_metas.first().unwrap().block_id
  }

  pub fn build(self) -> BuildDatabaseContext {
    self.build_context
  }
}

#[allow(dead_code)]
fn check_rows(fields: &[FieldRevision], rows: &[RowRevision]) -> SyncResult<()> {
  let field_ids = fields
    .iter()
    .map(|field| &field.id)
    .collect::<Vec<&String>>();
  for row in rows {
    let cell_field_ids = row.cells.keys().into_iter().collect::<Vec<&String>>();
    if cell_field_ids != field_ids {
      let msg = format!("{:?} contains invalid cells", row);
      return Err(SyncError::internal().context(msg));
    }
  }
  Ok(())
}
