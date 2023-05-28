use crate::database::database_editor::DatabaseEditorTest;
use flowy_database::services::export::CSVExport;

#[tokio::test]
async fn export_test() {
  let test = DatabaseEditorTest::new_grid().await;

  let s = CSVExport
    .export_database(&test.view_id, &test.editor)
    .await
    .unwrap();

  let mut reader = csv::Reader::from_reader(s.as_bytes());
  for header in reader.headers() {
    println!("{:?}", header);
  }

  let export_csv_records = reader.records();
  for record in export_csv_records {
    let record = record.unwrap();
    println!("{:?}", record);
  }
}
