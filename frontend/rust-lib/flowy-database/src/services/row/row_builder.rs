use crate::services::cell::{
  insert_checkbox_cell, insert_date_cell, insert_number_cell, insert_select_option_cell,
  insert_text_cell, insert_url_cell, FromCellString,
};

use crate::entities::FieldType;
use crate::services::field::{CheckboxCellData, SelectOptionIds};
use database_model::{gen_row_id, CellRevision, FieldRevision, RowRevision, DEFAULT_ROW_HEIGHT};
use indexmap::IndexMap;
use std::collections::HashMap;
use std::sync::Arc;

pub struct RowRevisionBuilder {
  block_id: String,
  field_rev_map: HashMap<String, Arc<FieldRevision>>,
  payload: CreateRowRevisionPayload,
}

impl RowRevisionBuilder {
  pub fn new(block_id: &str, fields: Vec<Arc<FieldRevision>>) -> Self {
    Self::new_with_data(block_id, fields, Default::default())
  }

  pub fn new_with_data(
    block_id: &str,
    field_revs: Vec<Arc<FieldRevision>>,
    cell_data_by_field_id: HashMap<String, String>,
  ) -> Self {
    let field_rev_map = field_revs
      .iter()
      .map(|field| (field.id.clone(), field.clone()))
      .collect::<HashMap<String, Arc<FieldRevision>>>();

    let payload = CreateRowRevisionPayload {
      row_id: gen_row_id(),
      cell_by_field_id: Default::default(),
      height: DEFAULT_ROW_HEIGHT,
      visibility: true,
    };

    let block_id = block_id.to_string();
    let mut builder = Self {
      block_id,
      field_rev_map,
      payload,
    };

    for (field_id, cell_data) in cell_data_by_field_id {
      if let Some(field_rev) = builder.field_rev_map.get(&field_id) {
        let field_type: FieldType = field_rev.ty.into();
        match field_type {
          FieldType::RichText => builder.insert_text_cell(&field_id, cell_data),
          FieldType::Number => {
            if let Ok(num) = cell_data.parse::<i64>() {
              builder.insert_date_cell(&field_id, num)
            }
          },
          FieldType::DateTime => {
            if let Ok(timestamp) = cell_data.parse::<i64>() {
              builder.insert_date_cell(&field_id, timestamp)
            }
          },
          FieldType::MultiSelect | FieldType::SingleSelect => {
            if let Ok(ids) = SelectOptionIds::from_cell_str(&cell_data) {
              builder.insert_select_option_cell(&field_id, ids.into_inner());
            }
          },
          FieldType::Checkbox => {
            if let Ok(value) = CheckboxCellData::from_cell_str(&cell_data) {
              builder.insert_checkbox_cell(&field_id, value.into_inner());
            }
          },
          FieldType::URL => {
            builder.insert_url_cell(&field_id, cell_data);
          },
          FieldType::Checklist => {
            if let Ok(ids) = SelectOptionIds::from_cell_str(&cell_data) {
              builder.insert_select_option_cell(&field_id, ids.into_inner());
            }
          },
        }
      }
    }
    builder
  }

  pub fn insert_text_cell(&mut self, field_id: &str, data: String) {
    match self.field_rev_map.get(&field_id.to_owned()) {
      None => tracing::warn!("Can't find the text field with id: {}", field_id),
      Some(field_rev) => {
        self
          .payload
          .cell_by_field_id
          .insert(field_id.to_owned(), insert_text_cell(data, field_rev));
      },
    }
  }

  pub fn insert_url_cell(&mut self, field_id: &str, data: String) {
    match self.field_rev_map.get(&field_id.to_owned()) {
      None => tracing::warn!("Can't find the url field with id: {}", field_id),
      Some(field_rev) => {
        self
          .payload
          .cell_by_field_id
          .insert(field_id.to_owned(), insert_url_cell(data, field_rev));
      },
    }
  }

  pub fn insert_number_cell(&mut self, field_id: &str, num: i64) {
    match self.field_rev_map.get(&field_id.to_owned()) {
      None => tracing::warn!("Can't find the number field with id: {}", field_id),
      Some(field_rev) => {
        self
          .payload
          .cell_by_field_id
          .insert(field_id.to_owned(), insert_number_cell(num, field_rev));
      },
    }
  }

  pub fn insert_checkbox_cell(&mut self, field_id: &str, is_check: bool) {
    match self.field_rev_map.get(&field_id.to_owned()) {
      None => tracing::warn!("Can't find the checkbox field with id: {}", field_id),
      Some(field_rev) => {
        self.payload.cell_by_field_id.insert(
          field_id.to_owned(),
          insert_checkbox_cell(is_check, field_rev),
        );
      },
    }
  }

  pub fn insert_date_cell(&mut self, field_id: &str, timestamp: i64) {
    match self.field_rev_map.get(&field_id.to_owned()) {
      None => tracing::warn!("Can't find the date field with id: {}", field_id),
      Some(field_rev) => {
        self
          .payload
          .cell_by_field_id
          .insert(field_id.to_owned(), insert_date_cell(timestamp, field_rev));
      },
    }
  }

  pub fn insert_select_option_cell(&mut self, field_id: &str, option_ids: Vec<String>) {
    match self.field_rev_map.get(&field_id.to_owned()) {
      None => tracing::warn!("Can't find the select option field with id: {}", field_id),
      Some(field_rev) => {
        self.payload.cell_by_field_id.insert(
          field_id.to_owned(),
          insert_select_option_cell(option_ids, field_rev),
        );
      },
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
