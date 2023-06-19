use std::time::Duration;

use flowy_database2::entities::FieldType;
use flowy_database2::services::field::DateCellData;
use lib_infra::util::timestamp;

use crate::database::block_test::script::DatabaseRowTest;
use crate::database::block_test::script::RowScript::*;

// Create a new row at the end of the grid and check the create time is valid.
#[tokio::test]
async fn created_at_field_test() {
  let mut test = DatabaseRowTest::new().await;
  let row_count = test.row_details.len();
  test
    .run_scripts(vec![CreateEmptyRow, AssertRowCount(row_count + 1)])
    .await;

  // Get created time of the new row.
  let row_detail = test.get_rows().await.last().cloned().unwrap();
  let updated_at_field = test.get_first_field(FieldType::CreatedTime);
  let cell = test
    .editor
    .get_cell(&updated_at_field.id, &row_detail.row.id)
    .await
    .unwrap();
  let created_at_timestamp = DateCellData::from(&cell).timestamp.unwrap();

  assert!(created_at_timestamp > 0);
  assert!(created_at_timestamp <= timestamp());
}

// Update row and check the update time is valid.
#[tokio::test]
async fn update_at_field_test() {
  let mut test = DatabaseRowTest::new().await;
  let row_detail = test.get_rows().await.remove(0);
  let last_edit_field = test.get_first_field(FieldType::LastEditedTime);
  let cell = test
    .editor
    .get_cell(&last_edit_field.id, &row_detail.row.id)
    .await
    .unwrap();
  let old_updated_at = DateCellData::from(&cell).timestamp.unwrap();

  tokio::time::sleep(Duration::from_millis(1000)).await;
  test
    .run_script(UpdateTextCell {
      row_id: row_detail.row.id.clone(),
      content: "test".to_string(),
    })
    .await;

  // Get the updated time of the row.
  let row_detail = test.get_rows().await.remove(0);
  let last_edit_field = test.get_first_field(FieldType::LastEditedTime);
  let cell = test
    .editor
    .get_cell(&last_edit_field.id, &row_detail.row.id)
    .await
    .unwrap();
  let new_updated_at = DateCellData::from(&cell).timestamp.unwrap();
  assert!(old_updated_at < new_updated_at);
}
