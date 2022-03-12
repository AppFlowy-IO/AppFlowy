use crate::client_grid::{make_block_meta_delta, make_grid_delta, GridBlockMetaDelta, GridMetaDelta};
use crate::errors::{CollaborateError, CollaborateResult};
use flowy_grid_data_model::entities::{Field, FieldType, GridBlock, GridBlockMeta, GridMeta, RowMeta};

pub struct GridBuilder {
    grid_id: String,
    fields: Vec<Field>,
    grid_block: GridBlock,
    grid_block_meta: GridBlockMeta,
}

impl GridBuilder {
    pub fn new(grid_id: &str) -> Self {
        let grid_block = GridBlock::new();
        let grid_block_meta = GridBlockMeta {
            block_id: grid_block.id.clone(),
            rows: vec![],
        };

        Self {
            grid_id: grid_id.to_owned(),
            fields: vec![],
            grid_block,
            grid_block_meta,
        }
    }

    pub fn add_field(mut self, field: Field) -> Self {
        self.fields.push(field);
        self
    }

    pub fn add_empty_row(mut self) -> Self {
        let row = RowMeta::new(&self.grid_block.id, vec![]);
        self.grid_block_meta.rows.push(row);
        self
    }

    pub fn build(self) -> CollaborateResult<BuildGridInfo> {
        let block_id = self.grid_block.id.clone();
        let grid_meta = GridMeta {
            grid_id: self.grid_id,
            fields: self.fields,
            blocks: vec![self.grid_block],
        };
        // let _ = check_rows(&self.fields, &self.rows)?;
        let grid_delta = make_grid_delta(&grid_meta);
        let grid_block_meta_delta = make_block_meta_delta(&self.grid_block_meta);
        Ok(BuildGridInfo {
            grid_delta,
            block_id,
            grid_block_meta_delta,
        })
    }
}

pub struct BuildGridInfo {
    pub grid_delta: GridMetaDelta,
    pub block_id: String,
    pub grid_block_meta_delta: GridBlockMetaDelta,
}

#[allow(dead_code)]
fn check_rows(fields: &[Field], rows: &[RowMeta]) -> CollaborateResult<()> {
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
    use crate::client_grid::GridBuilder;
    use flowy_grid_data_model::entities::{Field, FieldType, GridBlockMeta, GridMeta};

    #[test]
    fn create_default_grid_test() {
        let info = GridBuilder::new("1")
            .add_field(Field::new("Name", "", FieldType::RichText))
            .add_field(Field::new("Tags", "", FieldType::SingleSelect))
            .add_empty_row()
            .add_empty_row()
            .add_empty_row()
            .build()
            .unwrap();

        let grid_meta: GridMeta = serde_json::from_str(&info.grid_delta.to_str().unwrap()).unwrap();
        assert_eq!(grid_meta.fields.len(), 2);
        assert_eq!(grid_meta.blocks.len(), 1);

        let grid_block_meta: GridBlockMeta =
            serde_json::from_str(&info.grid_block_meta_delta.to_str().unwrap()).unwrap();
        assert_eq!(grid_block_meta.rows.len(), 3);

        assert_eq!(grid_meta.blocks[0].id, grid_block_meta.block_id);
    }
}
