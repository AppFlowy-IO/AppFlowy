use std::collections::HashMap;
use std::vec;

use chrono::NaiveDateTime;
use chrono::{offset, Duration};
use collab_database::fields::time_type_option::DateCellData;
use flowy_database2::entities::{CreateRowPayloadPB, FieldType};

use crate::database::group_test::script::DatabaseGroupTest;
use crate::database::group_test::script::GroupScript::*;

#[tokio::test]
async fn group_by_date_test() {
  let date_diffs = vec![-1, 0, 7, -15, -1];
  let mut test = DatabaseGroupTest::new().await;
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

  let scripts = vec![
    GroupByField {
      field_id: date_field.id.clone(),
    },
    AssertGroupCount(7),
    AssertGroupRowCount {
      group_index: 0,
      row_count: 0,
    },
    // Added via `make_test_board`
    AssertGroupId {
      group_index: 1,
      group_id: "2022/03/01".to_string(),
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 3,
    },
    // Added via `make_test_board`
    AssertGroupId {
      group_index: 2,
      group_id: "2022/11/01".to_string(),
    },
    AssertGroupRowCount {
      group_index: 2,
      row_count: 2,
    },
    AssertGroupId {
      group_index: 3,
      group_id: last_30_days,
    },
    AssertGroupRowCount {
      group_index: 3,
      row_count: 1,
    },
    AssertGroupId {
      group_index: 4,
      group_id: last_day,
    },
    AssertGroupRowCount {
      group_index: 4,
      row_count: 2,
    },
    AssertGroupId {
      group_index: 5,
      group_id: today.format("%Y/%m/%d").to_string(),
    },
    AssertGroupRowCount {
      group_index: 5,
      row_count: 1,
    },
    AssertGroupId {
      group_index: 6,
      group_id: next_7_days,
    },
    AssertGroupRowCount {
      group_index: 6,
      row_count: 1,
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn change_row_group_on_date_cell_changed_test() {
  let mut test = DatabaseGroupTest::new().await;
  let date_field = test.get_field(FieldType::DateTime).await;
  let scripts = vec![
    GroupByField {
      field_id: date_field.id.clone(),
    },
    AssertGroupCount(3),
    // Nov 2, 2022
    UpdateGroupedCellWithData {
      from_group_index: 1,
      row_index: 0,
      cell_data: "1667408732".to_string(),
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 2,
    },
    AssertGroupRowCount {
      group_index: 2,
      row_count: 3,
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn change_date_on_moving_row_to_another_group() {
  let mut test = DatabaseGroupTest::new().await;
  let date_field = test.get_field(FieldType::DateTime).await;
  let scripts = vec![
    GroupByField {
      field_id: date_field.id.clone(),
    },
    AssertGroupCount(3),
    AssertGroupRowCount {
      group_index: 1,
      row_count: 3,
    },
    AssertGroupRowCount {
      group_index: 2,
      row_count: 2,
    },
    MoveRow {
      from_group_index: 1,
      from_row_index: 0,
      to_group_index: 2,
      to_row_index: 0,
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 2,
    },
    AssertGroupRowCount {
      group_index: 2,
      row_count: 3,
    },
    AssertGroupId {
      group_index: 2,
      group_id: "2022/11/01".to_string(),
    },
  ];
  test.run_scripts(scripts).await;

  let group = test.group_at_index(2).await;
  let rows = group.clone().rows;
  let row_id = &rows.first().unwrap().id;
  let row = test
    .get_rows()
    .await
    .into_iter()
    .find(|r| r.id.to_string() == *row_id)
    .unwrap();
  let cell = row.cells.get(&date_field.id.clone()).unwrap();
  let date_cell = DateCellData::from(cell);

  let date_time =
    NaiveDateTime::parse_from_str("2022/11/01 00:00:00", "%Y/%m/%d %H:%M:%S").unwrap();
  assert_eq!(
    date_time.and_utc().timestamp(),
    date_cell.timestamp.unwrap()
  );
}
