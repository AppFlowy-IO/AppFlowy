use crate::entities::FieldType;

use crate::services::cell::TypeCellData;
use crate::services::database::DatabaseEditor;
use crate::services::field::{
  CheckboxTypeOptionPB, ChecklistTypeOptionPB, DateCellData, DateTypeOptionPB,
  MultiSelectTypeOptionPB, NumberTypeOptionPB, RichTextTypeOptionPB, SingleSelectTypeOptionPB,
  URLCellData,
};
use database_model::{FieldRevision, TypeOptionDataDeserializer};
use flowy_error::{FlowyError, FlowyResult};
use indexmap::IndexMap;
use serde::Serialize;
use serde_json::{json, Map, Value};
use std::collections::HashMap;

use std::sync::Arc;

#[derive(Debug, Clone, Serialize)]
pub struct ExportField {
  pub id: String,
  pub name: String,
  pub field_type: i64,
  pub visibility: bool,
  pub width: i64,
  pub type_options: HashMap<String, Value>,
  pub is_primary: bool,
}

#[derive(Debug, Clone, Serialize)]
struct ExportCell {
  data: String,
  field_type: FieldType,
}

impl From<&Arc<FieldRevision>> for ExportField {
  fn from(field_rev: &Arc<FieldRevision>) -> Self {
    let field_type = FieldType::from(field_rev.ty);
    let mut type_options: HashMap<String, Value> = HashMap::new();

    field_rev
      .type_options
      .iter()
      .filter(|(k, _)| k == &&field_rev.ty.to_string())
      .for_each(|(k, s)| {
        let value = match field_type {
          FieldType::RichText => {
            let pb = RichTextTypeOptionPB::from_json_str(s);
            serde_json::to_value(pb).unwrap()
          },
          FieldType::Number => {
            let pb = NumberTypeOptionPB::from_json_str(s);
            let mut map = Map::new();
            map.insert("format".to_string(), json!(pb.format as u8));
            map.insert("scale".to_string(), json!(pb.scale));
            map.insert("symbol".to_string(), json!(pb.symbol));
            map.insert("name".to_string(), json!(pb.name));
            Value::Object(map)
          },
          FieldType::DateTime => {
            let pb = DateTypeOptionPB::from_json_str(s);
            let mut map = Map::new();
            map.insert("date_format".to_string(), json!(pb.date_format as u8));
            map.insert("time_format".to_string(), json!(pb.time_format as u8));
            map.insert("field_type".to_string(), json!(FieldType::DateTime as u8));
            Value::Object(map)
          },
          FieldType::SingleSelect => {
            let pb = SingleSelectTypeOptionPB::from_json_str(s);
            let value = serde_json::to_string(&pb).unwrap();
            let mut map = Map::new();
            map.insert("content".to_string(), Value::String(value));
            Value::Object(map)
          },
          FieldType::MultiSelect => {
            let pb = MultiSelectTypeOptionPB::from_json_str(s);
            let value = serde_json::to_string(&pb).unwrap();
            let mut map = Map::new();
            map.insert("content".to_string(), Value::String(value));
            Value::Object(map)
          },
          FieldType::Checkbox => {
            let pb = CheckboxTypeOptionPB::from_json_str(s);
            serde_json::to_value(pb).unwrap()
          },
          FieldType::URL => {
            let pb = RichTextTypeOptionPB::from_json_str(s);
            serde_json::to_value(pb).unwrap()
          },
          FieldType::Checklist => {
            let pb = ChecklistTypeOptionPB::from_json_str(s);
            let value = serde_json::to_string(&pb).unwrap();
            let mut map = Map::new();
            map.insert("content".to_string(), Value::String(value));
            Value::Object(map)
          },
        };
        type_options.insert(k.clone(), value);
      });
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
    let mut field_by_field_id = IndexMap::new();
    field_revs.into_iter().for_each(|field| {
      field_by_field_id.insert(field.id.clone(), field);
    });
    for row_rev in row_revs {
      let cells = field_by_field_id
        .iter()
        .map(|(field_id, field)| {
          let field_type = FieldType::from(field.ty);
          let data = row_rev
            .cells
            .get(field_id)
            .map(|cell| TypeCellData::try_from(cell))
            .map(|data| {
              data
                .map(|data| match field_type {
                  FieldType::DateTime => {
                    match serde_json::from_str::<DateCellData>(&data.cell_str) {
                      Ok(cell_data) => cell_data.timestamp.unwrap_or_default().to_string(),
                      Err(_) => "".to_string(),
                    }
                  },
                  FieldType::URL => match serde_json::from_str::<URLCellData>(&data.cell_str) {
                    Ok(cell_data) => cell_data.content,
                    Err(_) => "".to_string(),
                  },
                  _ => data.cell_str,
                })
                .unwrap_or_default()
            })
            .unwrap_or_else(|| "".to_string());
          let cell = ExportCell { data, field_type };
          serde_json::to_string(&cell).unwrap()
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
