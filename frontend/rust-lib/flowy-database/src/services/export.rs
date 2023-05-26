use crate::entities::FieldType;
use crate::services::cell::{stringify_cell_data, TypeCellData};
use crate::services::database::DatabaseEditor;
use database_model::FieldRevision;
use flowy_error::{FlowyError, FlowyResult};
use serde::Serialize;
use std::collections::HashMap;
use std::sync::Arc;

#[derive(Debug, Clone, Serialize)]
pub struct ExportField {
  pub id: String,
  pub name: String,
  pub field_type: i64,
  pub visibility: bool,
  pub width: i64,
  pub type_options: HashMap<String, String>,
  pub is_primary: bool,
}

impl From<&Arc<FieldRevision>> for ExportField {
  fn from(field_rev: &Arc<FieldRevision>) -> Self {
    let type_options = field_rev
      .type_options
      .iter()
      .map(|(k, v)| (k.clone(), v.clone()))
      .collect();
    Self {
      id: field_rev.id.clone(),
      name: field_rev.name.clone(),
      field_type: field_rev.ty as i64,
      visibility: true,
      width: 100,
      type_options,
      is_primary: field_rev.is_primary,
    }
  }
}

pub struct CSVExport;
impl CSVExport {
  pub async fn export_database(
    &self,
    view_id: &str,
    database_editor: &Arc<DatabaseEditor>,
  ) -> FlowyResult<String> {
    let mut wtr = csv::Writer::from_writer(vec![]);
    let row_revs = database_editor.get_all_row_revs(view_id).await?;
    let field_revs = database_editor.get_field_revs(None).await?;

    // Write fields
    let field_records = field_revs
      .iter()
      .map(|field| ExportField::from(field))
      .map(|field| serde_json::to_string(&field).unwrap())
      .collect::<Vec<String>>();

    wtr
      .write_record(&field_records)
      .map_err(|e| FlowyError::internal().context(e))?;

    // Write rows
    let field_by_field_id = field_revs
      .into_iter()
      .map(|field| (field.id.clone(), field))
      .collect::<HashMap<_, _>>();
    for row_rev in row_revs {
      let cells = field_by_field_id
        .iter()
        .map(|(field_id, field)| match row_rev.cells.get(field_id) {
          None => "".to_string(),
          Some(cell) => match TypeCellData::try_from(cell) {
            Ok(data) => {
              let field_type = FieldType::from(field.ty);
              stringify_cell_data(data.cell_str, &field_type, &field_type, field.as_ref())
            },
            Err(_) => "".to_string(),
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
