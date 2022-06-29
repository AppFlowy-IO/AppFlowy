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
    pub fn add_field(mut self, field: FieldRevision) -> Self {
        self.build_context.field_revs.push(field);
        self
    }

    pub fn add_empty_row(mut self) -> Self {
        let row = RowRevision::new(&self.build_context.blocks.first().unwrap().block_id);
        let block_meta_rev = self.build_context.blocks.first_mut().unwrap();
        let block_rev = self.build_context.blocks_meta_data.first_mut().unwrap();
        block_rev.rows.push(Arc::new(row));
        block_meta_rev.row_count += 1;
        self
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

#[cfg(test)]
mod tests {
    use crate::client_grid::{make_block_meta_delta, make_grid_delta, GridBuilder};
    use flowy_grid_data_model::entities::FieldType;
    use flowy_grid_data_model::revision::{FieldRevision, GridBlockRevision, GridRevision};
    use std::sync::Arc;

    #[test]
    fn create_default_grid_test() {
        let grid_id = "1".to_owned();
        let build_context = GridBuilder::default()
            .add_field(FieldRevision::new("Name", "", FieldType::RichText, true))
            .add_field(FieldRevision::new("Tags", "", FieldType::SingleSelect, false))
            .add_empty_row()
            .add_empty_row()
            .add_empty_row()
            .build();

        let grid_rev = GridRevision {
            grid_id,
            fields: build_context.field_revs,
            blocks: build_context.blocks.into_iter().map(Arc::new).collect(),
            setting: Default::default(),
        };

        let grid_meta_delta = make_grid_delta(&grid_rev);
        let _: GridRevision = serde_json::from_str(&grid_meta_delta.to_str().unwrap()).unwrap();

        let grid_block_meta_delta = make_block_meta_delta(build_context.blocks_meta_data.first().unwrap());
        let _: GridBlockRevision = serde_json::from_str(&grid_block_meta_delta.to_str().unwrap()).unwrap();
    }
}
