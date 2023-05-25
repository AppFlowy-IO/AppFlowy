use crate::database::group_test::script::DatabaseGroupTest;
use crate::database::group_test::script::GroupScript::*;
use chrono::Duration;
use flowy_database2::entities::CreateRowParams;
use flowy_database2::entities::FieldType;
use std::collections::HashMap;
use std::vec;

#[tokio::test]
async fn group_by_date_test() {
  let date_diffs = vec![-1, 0, 7, -15, -1];
  let mut test = DatabaseGroupTest::new().await;
  let date_field = test.get_field(FieldType::DateTime).await;

  for diff in date_diffs {
    let timestamp = chrono::Utc::now()
      .checked_add_signed(Duration::days(diff))
      .unwrap()
      .timestamp()
      .to_string();
    let mut cells = HashMap::new();
    cells.insert(date_field.id.clone(), timestamp);

    let params = CreateRowParams {
      view_id: test.view_id.clone(),
      start_row_id: None,
      group_id: None,
      cell_data_by_field_id: Some(cells),
    };
    let res = test.editor.create_row(params).await;
    assert!(res.is_ok());
  }

  let today = chrono::Utc::now().date_naive();
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
    .checked_add_signed(Duration::days(7))
    .unwrap()
    .format("%Y/%m/%d")
    .to_string();

  let scripts = vec![
    GroupByField {
      field_id: date_field.id.clone(),
    },
    // Added via `make_test_board`
    AssertGroupRowCount {
      group_index: 0,
      row_count: 3,
    },
    AssertGroupIDName {
      group_index: 0,
      group_id: "2022/03/01".to_string(),
      group_name: "Mar 2022".to_string(),
    },
    // Added via `make_test_board`
    AssertGroupRowCount {
      group_index: 1,
      row_count: 2,
    },
    AssertGroupIDName {
      group_index: 1,
      group_id: "2022/11/01".to_string(),
      group_name: "Nov 2022".to_string(),
    },
    AssertGroupRowCount {
      group_index: 2,
      row_count: 1,
    },
    AssertGroupIDName {
      group_index: 2,
      group_id: last_30_days,
      group_name: "Last 30 days".to_string(),
    },
    AssertGroupRowCount {
      group_index: 3,
      row_count: 2,
    },
    AssertGroupIDName {
      group_index: 3,
      group_id: last_day,
      group_name: "Last day".to_string(),
    },
    AssertGroupRowCount {
      group_index: 4,
      row_count: 1,
    },
    AssertGroupIDName {
      group_index: 4,
      group_id: today.format("%Y/%m/%d").to_string(),
      group_name: "Today".to_string(),
    },
    AssertGroupRowCount {
      group_index: 5,
      row_count: 1,
    },
    AssertGroupIDName {
      group_index: 5,
      group_id: next_7_days,
      group_name: "Next 7 days".to_string(),
    },
    AssertGroupCount(6),
  ];
  test.run_scripts(scripts).await;
}
/*
#[tokio::test]
async fn group_alter_url_to_another_group_url_test() {
  let mut test = DatabaseGroupTest::new().await;
  let url_field = test.get_url_field().await;
  let scripts = vec![
    GroupByField {
      field_id: url_field.id.clone(),
    },
    // no status group
    AssertGroupRowCount {
      group_index: 0,
      row_count: 2,
    },
    // https://appflowy.io
    AssertGroupRowCount {
      group_index: 1,
      row_count: 2,
    },
    // https://github.com/AppFlowy-IO/AppFlowy
    AssertGroupRowCount {
      group_index: 2,
      row_count: 1,
    },
    // When moving the last row from 2nd group to 1nd group, the 2nd group will be removed
    UpdateGroupedCell {
      from_group_index: 2,
      row_index: 0,
      to_group_index: 1,
    },
    AssertGroupCount(2),
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn group_alter_url_to_new_url_test() {
  let mut test = DatabaseGroupTest::new().await;
  let url_field = test.get_url_field().await;
  let scripts = vec![
    GroupByField {
      field_id: url_field.id.clone(),
    },
    // When moving the last row from 2nd group to 1nd group, the 2nd group will be removed
    UpdateGroupedCellWithData {
      from_group_index: 0,
      row_index: 0,
      cell_data: "https://github.com/AppFlowy-IO".to_string(),
    },
    // no status group
    AssertGroupRowCount {
      group_index: 0,
      row_count: 1,
    },
    // https://appflowy.io
    AssertGroupRowCount {
      group_index: 1,
      row_count: 2,
    },
    // https://github.com/AppFlowy-IO/AppFlowy
    AssertGroupRowCount {
      group_index: 2,
      row_count: 1,
    },
    AssertGroupRowCount {
      group_index: 3,
      row_count: 1,
    },
    AssertGroupCount(4),
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn group_move_url_group_row_test() {
  let mut test = DatabaseGroupTest::new().await;
  let url_field = test.get_url_field().await;
  let scripts = vec![
    GroupByField {
      field_id: url_field.id.clone(),
    },
    // no status group
    AssertGroupRowCount {
      group_index: 0,
      row_count: 2,
    },
    // https://appflowy.io
    AssertGroupRowCount {
      group_index: 1,
      row_count: 2,
    },
    // https://github.com/AppFlowy-IO/AppFlowy
    AssertGroupRowCount {
      group_index: 2,
      row_count: 1,
    },
    AssertGroupCount(3),
    MoveRow {
      from_group_index: 0,
      from_row_index: 0,
      to_group_index: 1,
      to_row_index: 0,
    },
    AssertGroupRowCount {
      group_index: 0,
      row_count: 1,
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 3,
    },
    AssertGroupRowCount {
      group_index: 2,
      row_count: 1,
    },
  ];
  test.run_scripts(scripts).await;
}
*/
