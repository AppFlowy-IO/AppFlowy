use std::collections::HashMap;
use std::vec;

use chrono::NaiveDateTime;
use chrono::{offset, Duration};
use collab_database::database::gen_row_id;
use collab_database::rows::CreateRowParams;

use collab_database::views::OrderObjectPosition;
use flowy_database2::entities::FieldType;
use flowy_database2::services::cell::CellBuilder;
use flowy_database2::services::field::DateCellData;

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
    let cells = CellBuilder::with_cells(cells, &[date_field.clone()]).build();

    let params = CreateRowParams {
      id: gen_row_id(),
      cells,
      height: 60,
      visibility: true,
      row_position: OrderObjectPosition::default(),
      timestamp: 0,
    };
    let res = test.editor.create_row(&test.view_id, None, params).await;
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
    AssertGroupIDName {
      group_index: 1,
      group_id: "2022/03/01".to_string(),
      group_name: "Mar 2022".to_string(),
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 3,
    },
    // Added via `make_test_board`
    AssertGroupIDName {
      group_index: 2,
      group_id: "2022/11/01".to_string(),
      group_name: "Nov 2022".to_string(),
    },
    AssertGroupRowCount {
      group_index: 2,
      row_count: 2,
    },
    AssertGroupIDName {
      group_index: 3,
      group_id: last_30_days,
      group_name: "Last 30 days".to_string(),
    },
    AssertGroupRowCount {
      group_index: 3,
      row_count: 1,
    },
    AssertGroupIDName {
      group_index: 4,
      group_id: last_day,
      group_name: "Yesterday".to_string(),
    },
    AssertGroupRowCount {
      group_index: 4,
      row_count: 2,
    },
    AssertGroupIDName {
      group_index: 5,
      group_id: today.format("%Y/%m/%d").to_string(),
      group_name: "Today".to_string(),
    },
    AssertGroupRowCount {
      group_index: 5,
      row_count: 1,
    },
    AssertGroupIDName {
      group_index: 6,
      group_id: next_7_days,
      group_name: "Next 7 days".to_string(),
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
    AssertGroupIDName {
      group_index: 2,
      group_id: "2022/11/01".to_string(),
      group_name: "Nov 2022".to_string(),
    },
  ];
  test.run_scripts(scripts).await;

  let group = test.group_at_index(2).await;
  let rows = group.clone().rows;
  let row_id = &rows.get(0).unwrap().id;
  let row_detail = test
    .get_rows()
    .await
    .into_iter()
    .find(|r| r.row.id.to_string() == *row_id)
    .unwrap();
  let cell = row_detail.row.cells.get(&date_field.id.clone()).unwrap();
  let date_cell = DateCellData::from(cell);

  let date_time =
    NaiveDateTime::parse_from_str("2022/11/01 00:00:00", "%Y/%m/%d %H:%M:%S").unwrap();
  assert_eq!(date_time.timestamp(), date_cell.timestamp.unwrap());
}
