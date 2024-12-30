use crate::database::group_test::script::DatabaseGroupTest;
use chrono::{offset, Duration, NaiveDateTime};
use collab_database::fields::date_type_option::DateCellData;
use flowy_database2::entities::{CreateRowPayloadPB, FieldType};
use std::collections::HashMap;

#[tokio::test]
async fn group_by_date_test() {
  let date_diffs = vec![-1, 0, 7, -15, -1];
  let test = DatabaseGroupTest::new().await;
  let date_field = test.get_field(FieldType::DateTime).await;

  for diff in date_diffs {
    let timestamp = offset::Local::now()
      .checked_add_signed(Duration::days(diff))
      .unwrap()
      .timestamp()
      .to_string();

    let mut cells = HashMap::new();
    cells.insert(date_field.id.clone(), timestamp);

    let params = CreateRowPayloadPB {
      view_id: test.view_id.clone(),
      data: cells,
      ..Default::default()
    };

    let res = test.editor.create_row(params).await;
    assert!(res.is_ok());
  }

  let today = offset::Local::now();
  let last_day = today
    .checked_add_signed(Duration::days(-1))
    .unwrap()
    .format("%Y/%m/%d")
    .to_string();
  let last_30_days = today
    .checked_add_signed(Duration::days(-30))
    .unwrap()
    .format("%Y/%m/%d")
    .to_string();
  let next_7_days = today
    .checked_add_signed(Duration::days(2))
    .unwrap()
    .format("%Y/%m/%d")
    .to_string();

  // Group by date field
  test.group_by_field(&date_field.id).await;
  test.assert_group_count(7).await;

  test.assert_group_row_count(0, 0).await; // Empty group
  test.assert_group_id(1, "2022/03/01").await;
  test.assert_group_row_count(1, 3).await;
  test.assert_group_id(2, "2022/11/01").await;
  test.assert_group_row_count(2, 2).await;
  test.assert_group_id(3, &last_30_days).await;
  test.assert_group_row_count(3, 1).await;
  test.assert_group_id(4, &last_day).await;
  test.assert_group_row_count(4, 2).await;
  test
    .assert_group_id(5, &today.format("%Y/%m/%d").to_string())
    .await;
  test.assert_group_row_count(5, 1).await;
  test.assert_group_id(6, &next_7_days).await;
  test.assert_group_row_count(6, 1).await;
}

#[tokio::test]
async fn change_row_group_on_date_cell_changed_test() {
  let test = DatabaseGroupTest::new().await;
  let date_field = test.get_field(FieldType::DateTime).await;

  // Group by date field
  test.group_by_field(&date_field.id).await;
  test.assert_group_count(3).await;

  // Update date cell to a new timestamp
  test
    .update_grouped_cell_with_data(1, 0, "1667408732".to_string())
    .await;

  // Check that row counts in groups have updated correctly
  test.assert_group_row_count(1, 2).await;
  test.assert_group_row_count(2, 3).await;
}

#[tokio::test]
async fn change_date_on_moving_row_to_another_group() {
  let test = DatabaseGroupTest::new().await;
  let date_field = test.get_field(FieldType::DateTime).await;

  // Group by date field
  test.group_by_field(&date_field.id).await;
  test.assert_group_count(3).await;
  test.assert_group_row_count(1, 3).await;
  test.assert_group_row_count(2, 2).await;

  // Move a row from one group to another
  test.move_row(1, 0, 2, 0).await;

  // Verify row counts after the move
  test.assert_group_row_count(1, 2).await;
  test.assert_group_row_count(2, 3).await;
  test.assert_group_id(2, "2022/11/01").await;

  // Verify the timestamp of the moved row matches the new group's date
  let group = test.group_at_index(2).await;
  let rows = group.rows;
  let row_id = &rows.first().unwrap().id;
  let row = test
    .get_rows()
    .await
    .into_iter()
    .find(|r| r.id.to_string() == *row_id)
    .unwrap();
  let cell = row.cells.get(&date_field.id).unwrap();
  let date_cell = DateCellData::from(cell);

  let expected_date_time =
    NaiveDateTime::parse_from_str("2022/11/01 00:00:00", "%Y/%m/%d %H:%M:%S").unwrap();
  assert_eq!(
    expected_date_time.and_utc().timestamp(),
    date_cell.timestamp.unwrap()
  );
}
