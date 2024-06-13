use flowy_database2::entities::FieldType;
use flowy_database2::services::cell::stringify_cell;
use flowy_database2::services::field::CHECK;
use flowy_database2::services::share::csv::CSVFormat;

use crate::database::database_editor::DatabaseEditorTest;

#[tokio::test]
async fn export_meta_csv_test() {
  let test = DatabaseEditorTest::new_grid().await;
  let database = test.editor.clone();
  let s = database.export_csv(CSVFormat::META).await.unwrap();
  let mut reader = csv::Reader::from_reader(s.as_bytes());
  for header in reader.headers().unwrap() {
    dbg!(header);
  }

  let export_csv_records = reader.records();
  for record in export_csv_records {
    let record = record.unwrap();
    dbg!(record);
  }
}

#[tokio::test]
async fn export_and_then_import_meta_csv_test() {
  let test = DatabaseEditorTest::new_grid().await;
  let database = test.editor.clone();
  let format = CSVFormat::META;
  let csv_1 = database.export_csv(format).await.unwrap();

  let result = test.import(csv_1.clone(), format).await;
  let database = test.get_database(&result.database_id).await.unwrap();

  let fields = database.get_fields(&result.view_id, None);
  let rows = database.get_rows(&result.view_id).await.unwrap();
  assert_eq!(fields[0].field_type, 0);
  assert_eq!(fields[1].field_type, 1);
  assert_eq!(fields[2].field_type, 2);
  assert_eq!(fields[3].field_type, 3);
  assert_eq!(fields[4].field_type, 4);
  assert_eq!(fields[5].field_type, 5);
  assert_eq!(fields[6].field_type, 6);
  assert_eq!(fields[7].field_type, 7);
  assert_eq!(fields[8].field_type, 8);
  assert_eq!(fields[9].field_type, 9);

  for field in fields {
    for (index, row_detail) in rows.iter().enumerate() {
      if let Some(cell) = row_detail.row.cells.get(&field.id) {
        let field_type = FieldType::from(field.field_type);
        let s = stringify_cell(cell, &field);
        match &field_type {
          FieldType::RichText => {
            if index == 0 {
              assert_eq!(s, "A");
            }
          },
          FieldType::Number => {
            if index == 0 {
              assert_eq!(s, "$1");
            }
          },
          FieldType::DateTime => {
            if index == 0 {
              assert_eq!(s, "2022/03/14");
            }
          },
          FieldType::SingleSelect => {
            if index == 0 {
              assert_eq!(s, "");
            }
          },
          FieldType::MultiSelect => {
            if index == 0 {
              assert_eq!(s, "Google,Facebook");
            }
          },
          FieldType::Checkbox => {},
          FieldType::URL => {},
          FieldType::Checklist => {},
          FieldType::LastEditedTime => {},
          FieldType::CreatedTime => {},
          FieldType::Relation => {},
          FieldType::Summary => {},
          FieldType::Translate => {},
        }
      } else {
        panic!(
          "Can not found the cell with id: {} in {:?}",
          field.id, row_detail.row.cells
        );
      }
    }
  }
}

#[tokio::test]
async fn history_database_import_test() {
  let format = CSVFormat::META;
  let test = DatabaseEditorTest::new_grid().await;
  let csv = r#""{""id"":""TJCxFc"",""name"":""Name"",""field_type"":0,""visibility"":true,""width"":100,""type_options"":{""0"":{""data"":""""}},""is_primary"":true}","{""id"":""XbMTxa"",""name"":""Price"",""field_type"":1,""visibility"":true,""width"":100,""type_options"":{""1"":{""format"":1,""name"":""Number"",""scale"":0,""symbol"":""$""}},""is_primary"":false}","{""id"":""cPgMsM"",""name"":""Time"",""field_type"":2,""visibility"":true,""width"":100,""type_options"":{""2"":{""date_format"":1,""field_type"":2,""time_format"":1}},""is_primary"":false}","{""id"":""vCelOS"",""name"":""Status"",""field_type"":3,""visibility"":true,""width"":100,""type_options"":{""3"":{""content"":""{\""options\"":[{\""id\"":\""c_-f\"",\""name\"":\""Completed\"",\""color\"":\""Purple\""},{\""id\"":\""wQpG\"",\""name\"":\""Planned\"",\""color\"":\""Purple\""},{\""id\"":\""VLHf\"",\""name\"":\""Paused\"",\""color\"":\""Purple\""}],\""disable_color\"":false}""}},""is_primary"":false}","{""id"":""eQEcry"",""name"":""Platform"",""field_type"":4,""visibility"":true,""width"":100,""type_options"":{""4"":{""content"":""{\""options\"":[{\""id\"":\""edpw\"",\""name\"":\""Google\"",\""color\"":\""Purple\""},{\""id\"":\""cx0O\"",\""name\"":\""Facebook\"",\""color\"":\""Purple\""},{\""id\"":\""EsFR\"",\""name\"":\""Twitter\"",\""color\"":\""Purple\""}],\""disable_color\"":false}""}},""is_primary"":false}","{""id"":""KGlcPi"",""name"":""is urgent"",""field_type"":5,""visibility"":true,""width"":100,""type_options"":{""5"":{""is_selected"":false}},""is_primary"":false}","{""id"":""SBpJNI"",""name"":""link"",""field_type"":6,""visibility"":true,""width"":100,""type_options"":{""6"":{""data"":""""}},""is_primary"":false}","{""id"":""orSsPm"",""name"":""TODO"",""field_type"":7,""visibility"":true,""width"":100,""type_options"":{""7"":{""content"":""{\""options\"":[{\""id\"":\""HLXi\"",\""name\"":\""Wake up at 6:00 am\"",\""color\"":\""Purple\""},{\""id\"":\""CsGr\"",\""name\"":\""Get some coffee\"",\""color\"":\""Purple\""},{\""id\"":\""4WqN\"",\""name\"":\""Start working\"",\""color\"":\""Purple\""}],\""disable_color\"":false}""}},""is_primary"":false}"
"{""data"":""A"",""field_type"":0}","{""data"":""1"",""field_type"":1}","{""data"":""1647251762"",""field_type"":2}","{""data"":"""",""field_type"":3}","{""data"":""edpw,cx0O"",""field_type"":4}","{""data"":""Yes"",""field_type"":5}","{""data"":""AppFlowy website - https://www.appflowy.io"",""field_type"":6}","{""data"":""HLXi,CsGr,4WqN"",""field_type"":7}"
"{""data"":"""",""field_type"":0}","{""data"":""2"",""field_type"":1}","{""data"":""1647251762"",""field_type"":2}","{""data"":"""",""field_type"":3}","{""data"":""edpw,EsFR"",""field_type"":4}","{""data"":""Yes"",""field_type"":5}","{""data"":"""",""field_type"":6}","{""data"":"""",""field_type"":7}"
"{""data"":""C"",""field_type"":0}","{""data"":""3"",""field_type"":1}","{""data"":""1647251762"",""field_type"":2}","{""data"":""c_-f"",""field_type"":3}","{""data"":""cx0O"",""field_type"":4}","{""data"":""No"",""field_type"":5}","{""data"":"""",""field_type"":6}","{""data"":"""",""field_type"":7}"
"{""data"":""DA"",""field_type"":0}","{""data"":""14"",""field_type"":1}","{""data"":""1668704685"",""field_type"":2}","{""data"":""c_-f"",""field_type"":3}","{""data"":"""",""field_type"":4}","{""data"":""No"",""field_type"":5}","{""data"":"""",""field_type"":6}","{""data"":"""",""field_type"":7}"
"{""data"":""AE"",""field_type"":0}","{""data"":"""",""field_type"":1}","{""data"":""1668359085"",""field_type"":2}","{""data"":""wQpG"",""field_type"":3}","{""data"":"""",""field_type"":4}","{""data"":""No"",""field_type"":5}","{""data"":"""",""field_type"":6}","{""data"":"""",""field_type"":7}"
"{""data"":""AE"",""field_type"":0}","{""data"":""5"",""field_type"":1}","{""data"":""1671938394"",""field_type"":2}","{""data"":""wQpG"",""field_type"":3}","{""data"":"""",""field_type"":4}","{""data"":""Yes"",""field_type"":5}","{""data"":"""",""field_type"":6}","{""data"":"""",""field_type"":7}"
"#;
  let result = test.import(csv.to_string(), format).await;
  let database = test.get_database(&result.database_id).await.unwrap();

  let fields = database.get_fields(&result.view_id, None);
  let rows = database.get_rows(&result.view_id).await.unwrap();
  assert_eq!(fields[0].field_type, 0);
  assert_eq!(fields[1].field_type, 1);
  assert_eq!(fields[2].field_type, 2);
  assert_eq!(fields[3].field_type, 3);
  assert_eq!(fields[4].field_type, 4);
  assert_eq!(fields[5].field_type, 5);
  assert_eq!(fields[6].field_type, 6);
  assert_eq!(fields[7].field_type, 7);

  for field in fields {
    for (index, row_detail) in rows.iter().enumerate() {
      if let Some(cell) = row_detail.row.cells.get(&field.id) {
        let field_type = FieldType::from(field.field_type);
        let s = stringify_cell(cell, &field);
        match &field_type {
          FieldType::RichText => {
            if index == 0 {
              assert_eq!(s, "A");
            }
          },
          FieldType::Number => {
            if index == 0 {
              assert_eq!(s, "$1");
            }
          },
          FieldType::DateTime => {
            if index == 0 {
              assert_eq!(s, "2022/03/14");
            }
          },
          FieldType::SingleSelect => {
            if index == 0 {
              assert_eq!(s, "");
            }
          },
          FieldType::MultiSelect => {
            if index == 0 {
              assert_eq!(s, "Google,Facebook");
            }
          },
          FieldType::Checkbox => {
            if index == 0 {
              assert_eq!(s, CHECK);
            }
          },
          FieldType::URL => {
            if index == 0 {
              assert_eq!(s, "AppFlowy website - https://www.appflowy.io");
            }
          },
          FieldType::Checklist => {},
          FieldType::LastEditedTime => {},
          FieldType::CreatedTime => {},
          FieldType::Relation => {},
          FieldType::Summary => {},
          FieldType::Translate => {},
        }
      } else {
        panic!(
          "Can not found the cell with id: {} in {:?}",
          field.id, row_detail.row.cells
        );
      }
    }
  }
}
