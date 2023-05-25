use crate::entities::{DatabaseImportPB, FieldType};
use crate::services::cell::CellBuilder;
use crate::services::field::default_type_option_data_for_type;
use collab_database::database::{
  gen_database_id, gen_database_view_id, gen_field_id, gen_row_id, DatabaseData,
};
use collab_database::fields::Field;
use collab_database::rows::CreateRowParams;
use collab_database::views::{CreateDatabaseParams, DatabaseLayout};
use flowy_error::{FlowyError, FlowyResult};
use rayon::prelude::*;
use std::collections::HashMap;
use std::{fs::File, io::prelude::*};

#[derive(Default)]
pub struct CSVImporter;

impl CSVImporter {
  pub fn import_csv_from_file(&self, path: &str) -> FlowyResult<CreateDatabaseParams> {
    let mut file = File::open(path)?;
    let mut content = String::new();
    file.read_to_string(&mut content)?;
    let fields_with_rows = self.get_fields_and_rows(content)?;
    let database_data = database_from_fields_and_rows(fields_with_rows);
    Ok(database_data)
  }

  pub fn import_csv_from_string(&self, content: String) -> FlowyResult<CreateDatabaseParams> {
    let fields_with_rows = self.get_fields_and_rows(content)?;
    let database_data = database_from_fields_and_rows(fields_with_rows);
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
      .into_iter()
      .flat_map(|r| r.ok())
      .map(|record| {
        record
          .into_iter()
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

  let fields = fields
    .into_iter()
    .enumerate()
    .map(
      |(index, field_str)| match serde_json::from_str(&field_str) {
        Ok(field) => field,
        Err(_) => {
          let field_type = FieldType::RichText;
          let type_option_data = default_type_option_data_for_type(&field_type);
          let is_primary = index == 0;
          Field::new(
            gen_field_id(),
            field_str,
            field_type.clone().into(),
            is_primary,
          )
          .with_type_option_data(field_type, type_option_data)
        },
      },
    )
    .collect::<Vec<Field>>();

  let created_rows = rows
    .par_iter()
    .map(|row| {
      let mut cell_by_field_id = HashMap::new();
      let mut params = CreateRowParams::new(gen_row_id());
      for (index, cell) in row.iter().enumerate() {
        if let Some(field) = fields.get(index) {
          cell_by_field_id.insert(field.id.clone(), cell.to_string());
        }
      }
      params.cells = CellBuilder::with_cells(cell_by_field_id, &fields).build();
      params
    })
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
    created_rows,
    fields,
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
  fn test_import_csv_from_str() {
    let s = r#"Name,Tags,Number,Date,Checkbox,URL
1,tag 1,1,"May 26, 2023",Yes,appflowy.io
2,tag 2,2,"May 22, 2023",No,
,,,,Yes,"#;
    let importer = CSVImporter;
    let result = importer.import_csv_from_string(s.to_string()).unwrap();
    assert_eq!(result.created_rows.len(), 3);
    assert_eq!(result.fields.len(), 6);

    assert_eq!(result.fields[0].name, "Name");
    assert_eq!(result.fields[1].name, "Tags");
    assert_eq!(result.fields[2].name, "Number");
    assert_eq!(result.fields[3].name, "Date");
    assert_eq!(result.fields[4].name, "Checkbox");
    assert_eq!(result.fields[5].name, "URL");

    assert_eq!(result.created_rows[0].cells.len(), 6);
    assert_eq!(result.created_rows[1].cells.len(), 6);
    assert_eq!(result.created_rows[2].cells.len(), 6);

    println!("{:?}", result);
  }
}
