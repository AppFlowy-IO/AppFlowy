use crate::database::group_test::script::DatabaseGroupTest;
use crate::database::group_test::script::GroupScript::*;

#[tokio::test]
async fn group_group_by_url() {
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
  ];
  test.run_scripts(scripts).await;
}

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
