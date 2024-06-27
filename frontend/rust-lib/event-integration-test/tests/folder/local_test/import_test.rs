use crate::util::unzip;
use event_integration_test::EventIntegrationTest;
use flowy_core::DEFAULT_NAME;
use flowy_folder::entities::{ImportPayloadPB, ImportTypePB, ViewLayoutPB};

#[tokio::test]
async fn import_492_row_csv_file_test() {
  // csv_500r_15c.csv is a file with 492 rows and 17 columns
  let file_name = "csv_492r_17c.csv".to_string();
  let (cleaner, csv_file_path) = unzip("./tests/asset", &file_name).unwrap();

  let csv_string = std::fs::read_to_string(csv_file_path).unwrap();
  let test = EventIntegrationTest::new_with_name(DEFAULT_NAME).await;
  test.sign_up_as_anon().await;

  let workspace_id = test.get_current_workspace().await.id;
  let import_data = gen_import_data(file_name, csv_string, workspace_id);

  let view = test.import_data(import_data).await;
  let database = test.get_database(&view.id).await;
  assert_eq!(database.rows.len(), 492);
  drop(cleaner);
}

#[tokio::test]
async fn import_10240_row_csv_file_test() {
  // csv_22577r_15c.csv is a file with 10240 rows and 15 columns
  let file_name = "csv_10240r_15c.csv".to_string();
  let (cleaner, csv_file_path) = unzip("./tests/asset", &file_name).unwrap();

  let csv_string = std::fs::read_to_string(csv_file_path).unwrap();
  let test = EventIntegrationTest::new_with_name(DEFAULT_NAME).await;
  test.sign_up_as_anon().await;

  let workspace_id = test.get_current_workspace().await.id;
  let import_data = gen_import_data(file_name, csv_string, workspace_id);

  let view = test.import_data(import_data).await;
  let database = test.get_database(&view.id).await;
  assert_eq!(database.rows.len(), 10240);

  drop(cleaner);
}

fn gen_import_data(file_name: String, csv_string: String, workspace_id: String) -> ImportPayloadPB {
  let import_data = ImportPayloadPB {
    parent_view_id: workspace_id.clone(),
    name: file_name,
    data: Some(csv_string.as_bytes().to_vec()),
    file_path: None,
    view_layout: ViewLayoutPB::Grid,
    import_type: ImportTypePB::CSV,
  };
  import_data
}
