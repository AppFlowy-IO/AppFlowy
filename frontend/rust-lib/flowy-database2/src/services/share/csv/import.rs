use std::{fs::File, io::prelude::*};

use collab_database::database::{gen_database_id, gen_field_id, gen_row_id};
use collab_database::fields::Field;
use collab_database::rows::{new_cell_builder, Cell, CreateRowParams};
use collab_database::views::{CreateDatabaseParams, DatabaseLayout};

use flowy_error::{FlowyError, FlowyResult};

use crate::entities::FieldType;
use crate::services::field::{default_type_option_data_from_type, CELL_DATA};
use crate::services::field_settings::default_field_settings_for_fields;
use crate::services::share::csv::CSVFormat;

#[derive(Default)]
pub struct CSVImporter;

impl CSVImporter {
  pub fn import_csv_from_file(
    &self,
    view_id: &str,
    path: &str,
    style: CSVFormat,
  ) -> FlowyResult<CreateDatabaseParams> {
    let mut file = File::open(path)?;
    let mut content = String::new();
    file.read_to_string(&mut content)?;
    let fields_with_rows = self.get_fields_and_rows(content)?;
    let database_data = database_from_fields_and_rows(view_id, fields_with_rows, &style);
    Ok(database_data)
  }

  pub fn import_csv_from_string(
    &self,
    view_id: String,
    content: String,
    format: CSVFormat,
  ) -> FlowyResult<CreateDatabaseParams> {
    let fields_with_rows = self.get_fields_and_rows(content)?;
    let database_data = database_from_fields_and_rows(&view_id, fields_with_rows, &format);
    Ok(database_data)
  }

  fn get_fields_and_rows(&self, content: String) -> Result<FieldsRows, FlowyError> {
    let mut fields: Vec<String> = vec![];
    if content.is_empty() {
      return Err(FlowyError::invalid_data().with_context("Import content is empty"));
    }

    let mut reader = csv::Reader::from_reader(content.as_bytes());
    if let Ok(headers) = reader.headers() {
      for header in headers {
        fields.push(header.to_string());
      }
    } else {
      return Err(FlowyError::invalid_data().with_context("Header not found"));
    }

    let rows = reader
      .records()
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

fn database_from_fields_and_rows(
  view_id: &str,
  fields_and_rows: FieldsRows,
  format: &CSVFormat,
) -> CreateDatabaseParams {
  let (fields, rows) = fields_and_rows.split();
  let database_id = gen_database_id();

  let fields = fields
    .into_iter()
    .enumerate()
    .map(|(index, field_meta)| match format {
      CSVFormat::Original => default_field(field_meta, index == 0),
      CSVFormat::META => {
        //
        match serde_json::from_str(&field_meta) {
          Ok(field) => field,
          Err(e) => {
            dbg!(e);
            default_field(field_meta, index == 0)
          },
        }
      },
    })
    .collect::<Vec<Field>>();

  let field_settings = default_field_settings_for_fields(&fields, DatabaseLayout::Grid);

  let created_rows = rows
    .iter()
    .map(|cells| {
      let mut params = CreateRowParams::new(gen_row_id());
      for (index, cell_content) in cells.iter().enumerate() {
        if let Some(field) = fields.get(index) {
          let field_type = FieldType::from(field.field_type);

          // Make the cell based on the style.
          let cell = match format {
            CSVFormat::Original => new_cell_builder(field_type)
              .insert_str_value(CELL_DATA, cell_content.to_string())
              .build(),
            CSVFormat::META => match serde_json::from_str::<Cell>(cell_content) {
              Ok(cell) => cell,
              Err(_) => new_cell_builder(field_type)
                .insert_str_value(CELL_DATA, "".to_string())
                .build(),
            },
          };
          params.cells.insert(field.id.clone(), cell);
        }
      }
      params
    })
    .collect::<Vec<CreateRowParams>>();

  CreateDatabaseParams {
    database_id,
    view_id: view_id.to_string(),
    name: "".to_string(),
    layout: DatabaseLayout::Grid,
    layout_settings: Default::default(),
    filters: vec![],
    groups: vec![],
    sorts: vec![],
    created_rows,
    fields,
    field_settings,
  }
}

fn default_field(field_str: String, is_primary: bool) -> Field {
  let field_type = FieldType::RichText;
  let type_option_data = default_type_option_data_from_type(&field_type);
  Field::new(
    gen_field_id(),
    field_str,
    field_type.clone().into(),
    is_primary,
  )
  .with_type_option_data(field_type, type_option_data)
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

pub struct ImportResult {
  pub database_id: String,
  pub view_id: String,
}

#[cfg(test)]
mod tests {
  use collab_database::database::gen_database_view_id;

  use crate::services::share::csv::{CSVFormat, CSVImporter};

  #[test]
  fn test_import_csv_from_str() {
    let s = r#"Name,Tags,Number,Date,Checkbox,URL
1,tag 1,1,"May 26, 2023",Yes,appflowy.io
2,tag 2,2,"May 22, 2023",No,
,,,,Yes,"#;
    let importer = CSVImporter;
    let result = importer
      .import_csv_from_string(gen_database_view_id(), s.to_string(), CSVFormat::Original)
      .unwrap();
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

  #[test]
  fn import_empty_csv_data_test() {
    let s = r#""#;
    let importer = CSVImporter;
    let result =
      importer.import_csv_from_string(gen_database_view_id(), s.to_string(), CSVFormat::Original);
    assert!(result.is_err());
  }
}
