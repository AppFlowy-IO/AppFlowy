use crate::services::cell::apply_cell_data_changeset;
use crate::services::field::SelectOptionCellChangeset;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{gen_row_id, CellRevision, FieldRevision, RowRevision, DEFAULT_ROW_HEIGHT};
use indexmap::IndexMap;
use std::collections::HashMap;
use std::sync::Arc;

pub struct RowRevisionBuilder<'a> {
    block_id: String,
    field_rev_map: HashMap<&'a String, Arc<FieldRevision>>,
    payload: CreateRowRevisionPayload,
}

impl<'a> RowRevisionBuilder<'a> {
    pub fn new(block_id: &str, fields: &'a [Arc<FieldRevision>]) -> Self {
        let field_rev_map = fields
            .iter()
            .map(|field| (&field.id, field.clone()))
            .collect::<HashMap<&String, Arc<FieldRevision>>>();

        let payload = CreateRowRevisionPayload {
            row_id: gen_row_id(),
            cell_by_field_id: Default::default(),
            height: DEFAULT_ROW_HEIGHT,
            visibility: true,
        };

        let block_id = block_id.to_string();

        Self {
            block_id,
            field_rev_map,
            payload,
        }
    }

    pub fn insert_cell(&mut self, field_id: &str, data: String) -> FlowyResult<()> {
        match self.field_rev_map.get(&field_id.to_owned()) {
            None => {
                let msg = format!("Can't find the field with id: {}", field_id);
                Err(FlowyError::internal().context(msg))
            }
            Some(field_rev) => {
                let data = apply_cell_data_changeset(data, None, field_rev)?;
                let cell = CellRevision::new(data);
                self.payload.cell_by_field_id.insert(field_id.to_owned(), cell);
                Ok(())
            }
        }
    }

    pub fn insert_select_option_cell(&mut self, field_id: &str, data: String) {
        match self.field_rev_map.get(&field_id.to_owned()) {
            None => {
                tracing::warn!("Invalid field_id: {}", field_id);
            }
            Some(field_rev) => {
                let cell_data = SelectOptionCellChangeset::from_insert(&data).to_str();
                let data = apply_cell_data_changeset(cell_data, None, field_rev).unwrap();
                let cell = CellRevision::new(data);
                self.payload.cell_by_field_id.insert(field_id.to_owned(), cell);
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

    pub fn build(self) -> RowRevision {
        RowRevision {
            id: self.payload.row_id,
            block_id: self.block_id,
            cells: self.payload.cell_by_field_id,
            height: self.payload.height,
            visibility: self.payload.visibility,
        }
    }
}

pub struct CreateRowRevisionPayload {
    pub row_id: String,
    pub cell_by_field_id: IndexMap<String, CellRevision>,
    pub height: i32,
    pub visibility: bool,
}
