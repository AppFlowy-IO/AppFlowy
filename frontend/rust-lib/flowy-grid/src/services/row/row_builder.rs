use crate::services::row::apply_cell_data_changeset;

use crate::services::field::SelectOptionCellChangeset;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{CellMeta, FieldMeta, RowMeta, DEFAULT_ROW_HEIGHT};
use indexmap::IndexMap;
use std::collections::HashMap;

pub struct CreateRowMetaBuilder<'a> {
    field_meta_map: HashMap<&'a String, &'a FieldMeta>,
    payload: CreateRowMetaPayload,
}

impl<'a> CreateRowMetaBuilder<'a> {
    pub fn new(fields: &'a [FieldMeta]) -> Self {
        let field_meta_map = fields
            .iter()
            .map(|field| (&field.id, field))
            .collect::<HashMap<&String, &FieldMeta>>();

        let payload = CreateRowMetaPayload {
            row_id: uuid::Uuid::new_v4().to_string(),
            cell_by_field_id: Default::default(),
            height: DEFAULT_ROW_HEIGHT,
            visibility: true,
        };

        Self {
            field_meta_map,
            payload,
        }
    }

    pub fn add_cell(&mut self, field_id: &str, data: String) -> FlowyResult<()> {
        match self.field_meta_map.get(&field_id.to_owned()) {
            None => {
                let msg = format!("Invalid field_id: {}", field_id);
                Err(FlowyError::internal().context(msg))
            }
            Some(field_meta) => {
                let data = apply_cell_data_changeset(&data, None, field_meta)?;
                let cell = CellMeta::new(data);
                self.payload.cell_by_field_id.insert(field_id.to_owned(), cell);
                Ok(())
            }
        }
    }

    pub fn add_select_option_cell(&mut self, field_id: &str, data: String) -> FlowyResult<()> {
        match self.field_meta_map.get(&field_id.to_owned()) {
            None => {
                let msg = format!("Invalid field_id: {}", field_id);
                Err(FlowyError::internal().context(msg))
            }
            Some(field_meta) => {
                let cell_data = SelectOptionCellChangeset::from_insert(&data).cell_data();
                let data = apply_cell_data_changeset(&cell_data, None, field_meta)?;
                let cell = CellMeta::new(data);
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

    pub fn build(self) -> CreateRowMetaPayload {
        self.payload
    }
}

pub fn make_row_meta_from_context(block_id: &str, payload: CreateRowMetaPayload) -> RowMeta {
    RowMeta {
        id: payload.row_id,
        block_id: block_id.to_owned(),
        cells: payload.cell_by_field_id,
        height: payload.height,
        visibility: payload.visibility,
    }
}

pub struct CreateRowMetaPayload {
    pub row_id: String,
    pub cell_by_field_id: IndexMap<String, CellMeta>,
    pub height: i32,
    pub visibility: bool,
}
