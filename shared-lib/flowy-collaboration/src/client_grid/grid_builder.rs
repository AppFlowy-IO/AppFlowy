use crate::client_grid::{make_block_meta_delta, make_grid_delta, GridBlockMetaDelta, GridMetaDelta};
use crate::errors::{CollaborateError, CollaborateResult};
use flowy_grid_data_model::entities::{BuildGridContext, FieldMeta, GridBlock, GridBlockMeta, GridMeta, RowMeta};

pub struct GridBuilder {
    build_context: BuildGridContext,
}

impl std::default::Default for GridBuilder {
    fn default() -> Self {
        Self {
            build_context: Default::default(),
        }
    }
}

impl GridBuilder {
    pub fn add_field(mut self, field: FieldMeta) -> Self {
        self.build_context.field_metas.push(field);
        self
    }

    pub fn add_empty_row(mut self) -> Self {
        let row = RowMeta::new(&self.build_context.grid_block.id);
        self.build_context.grid_block_meta.rows.push(row);
        self.build_context.grid_block.row_count += 1;
        self
    }

    pub fn build(self) -> BuildGridContext {
        self.build_context
    }
}

#[allow(dead_code)]
fn check_rows(fields: &[FieldMeta], rows: &[RowMeta]) -> CollaborateResult<()> {
    let field_ids = fields.iter().map(|field| &field.id).collect::<Vec<&String>>();
    for row in rows {
        let cell_field_ids = row.cell_by_field_id.keys().into_iter().collect::<Vec<&String>>();
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
    use flowy_grid_data_model::entities::{FieldMeta, FieldType, GridBlockMeta, GridMeta};

    #[test]
    fn create_default_grid_test() {
        let grid_id = "1".to_owned();
        let build_context = GridBuilder::default()
            .add_field(FieldMeta::new("Name", "", FieldType::RichText))
            .add_field(FieldMeta::new("Tags", "", FieldType::SingleSelect))
            .add_empty_row()
            .add_empty_row()
            .add_empty_row()
            .build();

        let grid_meta = GridMeta {
            grid_id: grid_id.clone(),
            fields: build_context.field_metas,
            blocks: vec![build_context.grid_block],
        };

        let grid_meta_delta = make_grid_delta(&grid_meta);
        let _: GridMeta = serde_json::from_str(&grid_meta_delta.to_str().unwrap()).unwrap();

        let grid_block_meta_delta = make_block_meta_delta(&build_context.grid_block_meta);
        let _: GridBlockMeta = serde_json::from_str(&grid_block_meta_delta.to_str().unwrap()).unwrap();
    }
}
