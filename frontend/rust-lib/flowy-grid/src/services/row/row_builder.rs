use crate::services::field::select_option::SelectOptionCellContentChangeset;
use crate::services::row::apply_cell_data_changeset;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{gen_row_id, CellRevision, FieldRevision, RowRevision, DEFAULT_ROW_HEIGHT};
use indexmap::IndexMap;
use std::collections::HashMap;
use std::sync::Arc;

pub struct CreateRowRevisionBuilder<'a> {
    field_rev_map: HashMap<&'a String, &'a Arc<FieldRevision>>,
    payload: CreateRowRevisionPayload,
}

impl<'a> CreateRowRevisionBuilder<'a> {
    pub fn new(fields: &'a [Arc<FieldRevision>]) -> Self {
        let field_rev_map = fields
            .iter()
            .map(|field| (&field.id, field))
            .collect::<HashMap<&String, &Arc<FieldRevision>>>();

        let payload = CreateRowRevisionPayload {
            row_id: gen_row_id(),
            cell_by_field_id: Default::default(),
            height: DEFAULT_ROW_HEIGHT,
            visibility: true,
        };

        Self { field_rev_map, payload }
    }

    pub fn add_cell(&mut self, field_id: &str, data: String) -> FlowyResult<()> {
        match self.field_rev_map.get(&field_id.to_owned()) {
            None => {
                let msg = format!("Invalid field_id: {}", field_id);
                Err(FlowyError::internal().context(msg))
            }
            Some(field_rev) => {
                let data = apply_cell_data_changeset(&data, None, field_rev)?;
                let cell = CellRevision::new(data);
                self.payload.cell_by_field_id.insert(field_id.to_owned(), cell);
                Ok(())
            }
        }
    }

    pub fn add_select_option_cell(&mut self, field_id: &str, data: String) -> FlowyResult<()> {
        match self.field_rev_map.get(&field_id.to_owned()) {
            None => {
                let msg = format!("Invalid field_id: {}", field_id);
                Err(FlowyError::internal().context(msg))
            }
            Some(field_rev) => {
                let cell_data = SelectOptionCellContentChangeset::from_insert(&data).to_str();
                let data = apply_cell_data_changeset(&cell_data, None, field_rev)?;
                let cell = CellRevision::new(data);
                self.payload.cell_by_field_id.insert(field_id.to_owned(), cell);
                Ok(())
            }
        }
    }

    #[allow(dead_code)]
    pub fn height(mut self, height: i32) -> Self {
        self.payload.height = height;
        self
    }

    #[allow(dead_code)]
    pub fn visibility(mut self, visibility: bool) -> Self {
        self.payload.visibility = visibility;
        self
    }

    pub fn build(self) -> CreateRowRevisionPayload {
        self.payload
    }
}

pub fn make_row_rev_from_context(block_id: &str, payload: CreateRowRevisionPayload) -> RowRevision {
    RowRevision {
        id: payload.row_id,
        block_id: block_id.to_owned(),
        cells: payload.cell_by_field_id,
        height: payload.height,
        visibility: payload.visibility,
    }
}

pub struct CreateRowRevisionPayload {
    pub row_id: String,
    pub cell_by_field_id: IndexMap<String, CellRevision>,
    pub height: i32,
    pub visibility: bool,
}
