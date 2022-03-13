use flowy_grid_data_model::entities::{CellMeta, Field, RowMeta};

pub struct RowBuilder<'a> {
    fields: &'a Vec<Field>,
    row: RowMeta,
}

impl<'a> RowBuilder<'a> {
    pub fn new(fields: &'a Vec<Field>, block_id: &'a String) -> Self {
        let row = RowMeta::new(block_id);
        Self { fields, row }
    }

    #[allow(dead_code)]
    pub fn add_cell(mut self, field_id: &str, data: String) -> Self {
        let cell = CellMeta::new(field_id, data);
        self.row.cell_by_field_id.insert(field_id.to_owned(), cell);
        self
    }

    pub fn build(self) -> RowMeta {
        self.row
    }
}
