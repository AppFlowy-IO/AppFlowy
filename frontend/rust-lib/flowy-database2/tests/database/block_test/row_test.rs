use crate::database::block_test::script::DatabaseRowTest;
use crate::database::block_test::script::RowScript::*;
use flowy_database2::entities::FieldType;
use flowy_database2::services::field::DateCellData;
use lib_infra::util::timestamp;

// Create a new row at the end of the grid and check the create time is valid.
#[tokio::test]
async fn created_at_field_test() {
  let mut test = DatabaseRowTest::new().await;
  let row_count = test.rows.len();
  test
    .run_scripts(vec![CreateEmptyRow, AssertRowCount(row_count + 1)])
    .await;

  // Get created time of the new row.
  let row = test.get_rows().await.last().cloned().unwrap();
  let updated_at_field = test.get_first_field(FieldType::CreatedTime);
  let cell = row.cells.cell_for_field_id(&updated_at_field.id).unwrap();
  let created_at_timestamp = DateCellData::from(cell).timestamp.unwrap();

  assert!(created_at_timestamp > 0);
  assert!(created_at_timestamp < timestamp());
}

// Update row and check the update time is valid.
#[tokio::test]
async fn update_at_field_test() {
  let mut test = DatabaseRowTest::new().await;
  let row = test.get_rows().await.remove(0);
  let updated_at_field = test.get_first_field(FieldType::LastEditedTime);
  let cell = row.cells.cell_for_field_id(&updated_at_field.id).unwrap();
  let old_updated_at = DateCellData::from(cell).timestamp.unwrap();

  test
    .run_script(UpdateTextCell {
      row_id: row.id.clone(),
      content: "test".to_string(),
    })
    .await;

  // Get the updated time of the row.
  let row = test.get_rows().await.remove(0);
  let updated_at_field = test.get_first_field(FieldType::LastEditedTime);
  let cell = row.cells.cell_for_field_id(&updated_at_field.id).unwrap();
  let new_updated_at = DateCellData::from(cell).timestamp.unwrap();

  assert!(old_updated_at < new_updated_at);
}
