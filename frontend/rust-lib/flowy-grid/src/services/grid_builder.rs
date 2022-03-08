use crate::manager::GridManager;
use flowy_collaboration::client_grid::make_grid_delta;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{Field, FieldOrder, FieldType, Grid, RawCell, RawRow, RowOrder};
use lib_infra::uuid;
use std::sync::Arc;

pub struct GridBuilder {
    grid_manager: Arc<GridManager>,
    grid_id: String,
    fields: Vec<Field>,
    rows: Vec<RawRow>,
}

impl GridBuilder {
    pub fn new(grid_id: &str, grid_manager: Arc<GridManager>) -> Self {
        Self {
            grid_manager,
            grid_id: grid_id.to_owned(),
            fields: vec![],
            rows: vec![],
        }
    }

    pub fn add_field(mut self, name: &str, desc: &str, field_type: FieldType) -> Self {
        let field = Field::new(&uuid(), name, desc, field_type);
        self.fields.push(field);
        self
    }

    pub fn add_empty_row(mut self) -> Self {
        let row = RawRow::new(&uuid(), &self.grid_id, vec![]);
        self.rows.push(row);
        self
    }

    pub fn add_row(mut self, cells: Vec<RawCell>) -> Self {
        let row = RawRow::new(&uuid(), &self.grid_id, cells);
        self.rows.push(row);
        self
    }

    pub fn build(self) -> FlowyResult<String> {
        let field_orders = self.fields.iter().map(FieldOrder::from).collect::<Vec<FieldOrder>>();

        let row_orders = self.rows.iter().map(RowOrder::from).collect::<Vec<RowOrder>>();

        let grid = Grid {
            id: self.grid_id,
            field_orders: field_orders.into(),
            row_orders: row_orders.into(),
        };

        // let _ = check_rows(&self.fields, &self.rows)?;
        let _ = self.grid_manager.save_rows(self.rows)?;
        let _ = self.grid_manager.save_fields(self.fields)?;

        let delta = make_grid_delta(&grid);
        Ok(delta.to_delta_str())
    }
}

#[allow(dead_code)]
fn check_rows(fields: &[Field], rows: &[RawRow]) -> FlowyResult<()> {
    let field_ids = fields.iter().map(|field| &field.id).collect::<Vec<&String>>();
    for row in rows {
        let cell_field_ids = row.cell_by_field_id.keys().into_iter().collect::<Vec<&String>>();
        if cell_field_ids != field_ids {
            let msg = format!("{:?} contains invalid cells", row);
            return Err(FlowyError::internal().context(msg));
        }
    }
    Ok(())
}

pub fn make_default_grid(grid_id: &str, grid_manager: Arc<GridManager>) -> String {
    GridBuilder::new(grid_id, grid_manager)
        .add_field("Name", "", FieldType::RichText)
        .add_field("Tags", "", FieldType::SingleSelect)
        .add_empty_row()
        .add_empty_row()
        .build()
        .unwrap()
}
