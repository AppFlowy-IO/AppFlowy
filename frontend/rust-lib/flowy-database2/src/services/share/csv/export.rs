use crate::entities::FieldType;
use crate::services::cell::stringify_cell_data;
use collab_database::database::Database;

use flowy_error::{FlowyError, FlowyResult};
use std::collections::HashMap;

pub enum ExportStyle {
  /// The export data will be pure data, without any meta data.
  /// Will lost the field type information.
  SIMPLE,
  /// The export data contains meta data, such as field type.
  /// It can be used to fully restore the database.
  META,
}

pub struct CSVExport;
impl CSVExport {
  pub fn export_database(&self, database: &Database, style: ExportStyle) -> FlowyResult<String> {
    let mut wtr = csv::Writer::from_writer(vec![]);
    let inline_view_id = database.get_inline_view_id();
    let fields = database.get_fields(&inline_view_id, None);

    // Write fields
    let field_records = fields
      .iter()
      .map(|field| match &style {
        ExportStyle::SIMPLE => field.name.clone(),
        ExportStyle::META => serde_json::to_string(&field).unwrap(),
      })
      .collect::<Vec<String>>();
    wtr
      .write_record(&field_records)
      .map_err(|e| FlowyError::internal().context(e))?;

    // Write rows
    let field_by_field_id = fields
      .into_iter()
      .map(|field| (field.id.clone(), field))
      .collect::<HashMap<_, _>>();
    let rows = database.get_rows_for_view(&inline_view_id);
    for row in rows {
      let cells = field_by_field_id
        .iter()
        .map(|(field_id, field)| match row.cells.get(field_id) {
          None => "".to_string(),
          Some(cell) => {
            let field_type = FieldType::from(field.field_type);
            match style {
              ExportStyle::SIMPLE => stringify_cell_data(cell, &field_type, &field_type, field),
              ExportStyle::META => serde_json::to_string(cell).unwrap_or_else(|_| "".to_string()),
            }
          },
        })
        .collect::<Vec<_>>();

      if let Err(e) = wtr.write_record(&cells) {
        tracing::warn!("CSV failed to write record: {}", e);
      }
    }

    let data = wtr
      .into_inner()
      .map_err(|e| FlowyError::internal().context(e))?;
    let csv = String::from_utf8(data).map_err(|e| FlowyError::internal().context(e))?;
    Ok(csv)
  }
}
