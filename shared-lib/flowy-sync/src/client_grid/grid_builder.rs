use crate::errors::{CollaborateError, CollaborateResult};
use flowy_grid_data_model::revision::{
    BuildGridContext, FieldRevision, GridBlockMetaRevision, GridBlockRevision, RowRevision,
};
use std::sync::Arc;

pub struct GridBuilder {
    build_context: BuildGridContext,
}

impl std::default::Default for GridBuilder {
    fn default() -> Self {
        let mut build_context = BuildGridContext::new();

        let block_meta = GridBlockMetaRevision::new();
        let block_meta_data = GridBlockRevision {
            block_id: block_meta.block_id.clone(),
            rows: vec![],
        };

        build_context.blocks.push(block_meta);
        build_context.blocks_meta_data.push(block_meta_data);

        GridBuilder { build_context }
    }
}

impl GridBuilder {
    pub fn new() -> Self {
        Self::default()
    }
    pub fn add_field(&mut self, field: FieldRevision) {
        self.build_context.field_revs.push(field);
    }

    pub fn add_row(&mut self, row_rev: RowRevision) {
        let block_meta_rev = self.build_context.blocks.first_mut().unwrap();
        let block_rev = self.build_context.blocks_meta_data.first_mut().unwrap();
        block_rev.rows.push(Arc::new(row_rev));
        block_meta_rev.row_count += 1;
    }

    pub fn add_empty_row(&mut self) {
        let row = RowRevision::new(&self.build_context.blocks.first().unwrap().block_id);
        self.add_row(row);
    }

    pub fn build(self) -> BuildGridContext {
        self.build_context
    }
}

#[allow(dead_code)]
fn check_rows(fields: &[FieldRevision], rows: &[RowRevision]) -> CollaborateResult<()> {
    let field_ids = fields.iter().map(|field| &field.id).collect::<Vec<&String>>();
    for row in rows {
        let cell_field_ids = row.cells.keys().into_iter().collect::<Vec<&String>>();
        if cell_field_ids != field_ids {
            let msg = format!("{:?} contains invalid cells", row);
            return Err(CollaborateError::internal().context(msg));
        }
    }
    Ok(())
}
