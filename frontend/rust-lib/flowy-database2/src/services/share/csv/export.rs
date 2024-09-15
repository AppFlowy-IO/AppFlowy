use collab_database::database::Database;
use collab_database::fields::Field;
use collab_database::rows::Cell;
use futures::StreamExt;
use indexmap::IndexMap;

use flowy_error::{FlowyError, FlowyResult};

use crate::entities::FieldType;
use crate::services::cell::stringify_cell;
use crate::services::field::{TimestampCellData, TimestampCellDataWrapper};

#[derive(Debug, Clone, Copy)]
pub enum CSVFormat {
  /// The export data will be pure data, without any meta data.
  /// Will lost the field type information.
  Original,
  /// The export data contains meta data, such as field type.
  /// It can be used to fully restore the database.
  META,
}

pub struct CSVExport;
impl CSVExport {
  pub async fn export_database(
    &self,
    database: &Database,
    style: CSVFormat,
  ) -> FlowyResult<String> {
    let mut wtr = csv::Writer::from_writer(vec![]);
    let inline_view_id = database.get_inline_view_id();
    let fields = database.get_fields_in_view(&inline_view_id, None);

    // Write fields
    let field_records = fields
      .iter()
      .map(|field| match &style {
        CSVFormat::Original => field.name.clone(),
        CSVFormat::META => serde_json::to_string(&field).unwrap(),
      })
      .collect::<Vec<String>>();
    wtr
      .write_record(&field_records)
      .map_err(|e| FlowyError::internal().with_context(e))?;

    // Write rows
    let mut field_by_field_id = IndexMap::new();
    fields.into_iter().for_each(|field| {
      field_by_field_id.insert(field.id.clone(), field);
    });
    let rows = database
      .get_rows_for_view(&inline_view_id, None)
      .await
      .filter_map(|result| async { result.ok() })
      .collect::<Vec<_>>()
      .await;

    let stringify = |cell: &Cell, field: &Field, style: CSVFormat| match style {
      CSVFormat::Original => stringify_cell(cell, field),
      CSVFormat::META => serde_json::to_string(cell).unwrap_or_else(|_| "".to_string()),
    };

    for row in rows {
      let cells = field_by_field_id
        .iter()
        .map(|(field_id, field)| {
          let field_type = FieldType::from(field.field_type);
          match field_type {
            FieldType::LastEditedTime | FieldType::CreatedTime => {
              let cell_data = if field_type.is_created_time() {
                TimestampCellData::new(row.created_at)
              } else {
                TimestampCellData::new(row.modified_at)
              };
              let cell = Cell::from(TimestampCellDataWrapper::from((field_type, cell_data)));
              stringify(&cell, field, style)
            },
            _ => match row.cells.get(field_id) {
              None => "".to_string(),
              Some(cell) => stringify(cell, field, style),
            },
          }
        })
        .collect::<Vec<_>>();

      if let Err(e) = wtr.write_record(&cells) {
        tracing::warn!("CSV failed to write record: {}", e);
      }
    }

    let data = wtr
      .into_inner()
      .map_err(|e| FlowyError::internal().with_context(e))?;
    let csv = String::from_utf8(data).map_err(|e| FlowyError::internal().with_context(e))?;
    Ok(csv)
  }
}
