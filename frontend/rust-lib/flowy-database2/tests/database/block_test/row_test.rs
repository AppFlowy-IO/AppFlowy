use collab_database::fields::date_type_option::DateCellData;
use flowy_database2::entities::FieldType;
use lib_infra::util::timestamp;
use std::time::Duration;

use crate::database::block_test::script::DatabaseRowTest;

#[tokio::test]
async fn created_at_field_test() {
  let mut test = DatabaseRowTest::new().await;

  // Get initial row count
  let row_count = test.rows.len();

  // Create a new row and assert the row count has increased by 1
  test.create_empty_row().await;
  test.assert_row_count(row_count + 1).await;

  // Get created time of the new row.
  let row = test.get_rows().await.last().cloned().unwrap();
  let created_at_field = test.get_first_field(FieldType::CreatedTime).await;
  let cell = test
    .editor
    .get_cell(&created_at_field.id, &row.id)
    .await
    .unwrap();
  let created_at_timestamp = DateCellData::from(&cell).timestamp.unwrap();

  assert!(created_at_timestamp > 0);
  assert!(created_at_timestamp <= timestamp());
}

#[tokio::test]
async fn update_at_field_test() {
  let mut test = DatabaseRowTest::new().await;

  // Get the first row and the current LastEditedTime field
  let row = test.get_rows().await.remove(0);
  let last_edit_field = test.get_first_field(FieldType::LastEditedTime).await;
  let cell = test
    .editor
    .get_cell(&last_edit_field.id, &row.id)
    .await
    .unwrap();
  let old_updated_at = DateCellData::from(&cell).timestamp.unwrap();

  // Wait for 1 second before updating the row
  tokio::time::sleep(Duration::from_millis(1000)).await;

  // Update the text cell of the first row
  test.update_text_cell(row.id.clone(), "test").await;

  // Get the updated time of the row
  let row = test.get_rows().await.remove(0);
  let last_edit_field = test.get_first_field(FieldType::LastEditedTime).await;
  let cell = test
    .editor
    .get_cell(&last_edit_field.id, &row.id)
    .await
    .unwrap();
  let new_updated_at = DateCellData::from(&cell).timestamp.unwrap();

  assert!(old_updated_at < new_updated_at);
}
