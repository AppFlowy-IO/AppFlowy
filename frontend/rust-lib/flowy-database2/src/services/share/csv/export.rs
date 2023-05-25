use crate::entities::FieldType;
use crate::services::cell::stringify_cell_data;
use collab_database::database::Database;
use collab_database::fields::Field;
use flowy_error::{FlowyError, FlowyResult};
use std::collections::HashMap;

pub struct CSVExport;

impl CSVExport {
  pub fn export_database(&self, database: Database) -> FlowyResult<String> {
    let mut wtr = csv::Writer::from_writer(vec![]);
    let inline_view_id = database.get_inline_view_id();
    let fields = database.get_fields(&inline_view_id, None);

    for field in &fields {
      wtr
        .write_record(&[serde_json::to_string(field).unwrap()])
        .map_err(|e| FlowyError::internal().context(e))?;
    }
    let field_by_field_id = fields
      .into_iter()
      .map(|field| (field.id.clone(), field))
      .collect::<HashMap<_, _>>();
    let rows = database.get_rows_for_view(&inline_view_id);
    for row in rows {
      let cells = row
        .cells
        .into_iter()
        .flat_map(|(field_id, cell)| match field_by_field_id.get(&field_id) {
          None => {
            tracing::warn!("Field not found for field_id: {}", field_id);
            None
          },
          Some(field) => {
            let field_type = FieldType::from(field.field_type);
            Some(stringify_cell_data(&cell, &field_type, &field_type, field))
          },
        })
        .collect::<Vec<String>>();
      let _ = wtr.write_record(&cells);
    }

    let data = wtr
      .into_inner()
      .map_err(|e| FlowyError::internal().context(e))?;
    let csv = String::from_utf8(data).map_err(|e| FlowyError::internal().context(e))?;
    Ok(csv)
  }
}
