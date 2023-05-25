use crate::database::database_editor::DatabaseEditorTest;
use flowy_database2::services::share::csv::ExportStyle;

#[tokio::test]
async fn export_and_then_import_test() {
  let test = DatabaseEditorTest::new_grid().await;
  let database = test.editor.clone();
  let csv_1 = database.export_csv(ExportStyle::SIMPLE).await.unwrap();

  let imported_database_id = test.import(csv_1.clone()).await;
  let csv_2 = test
    .get_database(&imported_database_id)
    .await
    .unwrap()
    .export_csv(ExportStyle::SIMPLE)
    .await
    .unwrap();

  let mut reader = csv::Reader::from_reader(csv_1.as_bytes());
  let export_csv_records_1 = reader.records();

  let mut reader = csv::Reader::from_reader(csv_2.as_bytes());
  let export_csv_records_2 = reader.records();

  let mut a = export_csv_records_1
    .map(|v| v.unwrap())
    .flat_map(|v| v.iter().map(|v| v.to_string()).collect::<Vec<_>>())
    .collect::<Vec<String>>();
  let mut b = export_csv_records_2
    .map(|v| v.unwrap())
    .flat_map(|v| v.iter().map(|v| v.to_string()).collect::<Vec<_>>())
    .collect::<Vec<String>>();
  a.sort();
  b.sort();
  assert_eq!(a, b);
}
