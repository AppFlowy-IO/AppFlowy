use crate::database::block_test::script::DatabaseRowTest;
use crate::database::block_test::script::RowScript::*;
use flowy_database2::entities::FieldType;
use flowy_database2::services::field::DateCellData;

#[tokio::test]
async fn set_created_at_field_on_create_row() {
  let mut test = DatabaseRowTest::new().await;
  let row_count = test.rows.len();

  let before_create_timestamp = chrono::offset::Utc::now().timestamp();
  test
    .run_scripts(vec![CreateEmptyRow, AssertRowCount(row_count + 1)])
    .await;
  let after_create_timestamp = chrono::offset::Utc::now().timestamp();

  let mut rows = test.rows.clone();
  rows.sort_by(|r1, r2| r1.created_at.cmp(&r2.created_at));
  let row = rows.last().unwrap();

  let fields = test.fields.clone();
  let created_at_field = fields
    .iter()
    .find(|&f| FieldType::from(f.field_type) == FieldType::CreatedAt)
    .unwrap();
  let cell = row.cells.cell_for_field_id(&created_at_field.id).unwrap();
  let created_at_timestamp = DateCellData::from(cell).timestamp.unwrap();

  assert!(
    created_at_timestamp >= before_create_timestamp
      && created_at_timestamp <= after_create_timestamp,
    "timestamp: {}, before: {}, after: {}",
    created_at_timestamp,
    before_create_timestamp,
    after_create_timestamp
  );

  let updated_at_field = fields
    .iter()
    .find(|&f| FieldType::from(f.field_type) == FieldType::UpdatedAt)
    .unwrap();
  let cell = row.cells.cell_for_field_id(&updated_at_field.id).unwrap();
  let updated_at_timestamp = DateCellData::from(cell).timestamp.unwrap();

  assert!(
    updated_at_timestamp >= before_create_timestamp
      && updated_at_timestamp <= after_create_timestamp,
    "timestamp: {}, before: {}, after: {}",
    updated_at_timestamp,
    before_create_timestamp,
    after_create_timestamp
  );
}
