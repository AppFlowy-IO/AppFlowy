use crate::entities::{CreateRowParams, DatabaseImportPB};
use crate::{errors::*, import::*};
use collab_database::database::{gen_database_id, gen_database_view_id, DatabaseData};
use collab_database::views::{CreateDatabaseParams, DatabaseLayout};
use flowy_error::{FlowyError, FlowyResult};
use flowy_store::entities::share::FlowyResource;
use rayon::prelude::*;
use std::{fs::File, io::prelude::*};

#[derive(Default)]
pub struct CSVImporter {}

impl CSVImporter {
  pub fn import_csv_from_file(&self, path: &str) -> FlowyResult<CreateDatabaseParams> {
    let mut file = File::open(path)?;
    let mut content = String::new();
    file.read_to_string(&mut content)?;
    let fields_with_rows = self.get_fields_and_rows(content)?;
    let database_data = database_from_fields_and_rows(fields_with_rows)?;
    Ok(database_data)
  }

  pub fn import_csv_from_string(&self, content: String) -> FlowyResult<CreateDatabaseParams> {
    let fields_with_rows = self.get_fields_and_rows(content)?;
    let database_data = database_from_fields_and_rows(fields_with_rows)?;
    Ok(database_data)
  }

  fn get_fields_and_rows(&self, content: String) -> Result<FieldsRows, FlowyError> {
    let mut fields: Vec<String> = vec![];
    if content.is_empty() {
      return Err(FlowyError::invalid_data().context("Import content is empty"));
    }

    let mut reader = csv::Reader::from_reader(content.as_bytes());
    if let Ok(headers) = reader.headers() {
      for header in headers {
        fields.push(header.to_string());
      }
    } else {
      return Err(FlowyError::invalid_data().context("Header not found"));
    }

    let rows = reader
      .records()
      .par_iter()
      .flat_map(|r| r.ok())
      .map(|record| {
        record
          .par_iter()
          .map(|s| s.to_string())
          .collect::<Vec<String>>()
      })
      .collect();

    Ok(FieldsRows { fields, rows })
  }
}

fn database_from_fields_and_rows(fields_and_rows: FieldsRows) -> CreateDatabaseParams {
  let (fields, rows) = fields_and_rows.split();
  let view_id = gen_database_view_id();
  let database_id = gen_database_id();

  let created_rows = rows
    .par_iter()
    .map(|row| for cell in row {})
    .collect::<Vec<CreateRowParams>>();

  CreateDatabaseParams {
    database_id,
    view_id,
    name: "".to_string(),
    layout: DatabaseLayout::Grid,
    layout_settings: Default::default(),
    filters: vec![],
    groups: vec![],
    sorts: vec![],
    created_rows: vec![],
    fields: vec![],
  }
}

struct FieldsRows {
  fields: Vec<String>,
  rows: Vec<Vec<String>>,
}
impl FieldsRows {
  fn split(self) -> (Vec<String>, Vec<Vec<String>>) {
    (self.fields, self.rows)
  }
}

#[cfg(test)]
mod tests {
  use crate::services::share::csv::CSVImporter;

  #[test]
  fn test_import_csv_from_file() {
    let importer = CSVImporter::default();
    let result = importer.import_csv_from_file("test.csv").unwrap();
    assert!(result.is_ok());
  }
}
