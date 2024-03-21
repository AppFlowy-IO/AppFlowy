use flowy_database2::services::field::SelectOption;

use crate::database::group_test::script::DatabaseGroupTest;
use crate::database::group_test::script::GroupScript::*;

#[tokio::test]
async fn group_init_test() {
  let mut test = DatabaseGroupTest::new().await;
  let scripts = vec![
    AssertGroupCount(4),
    AssertGroupRowCount {
      group_index: 1,
      row_count: 2,
    },
    AssertGroupRowCount {
      group_index: 2,
      row_count: 2,
    },
    AssertGroupRowCount {
      group_index: 3,
      row_count: 1,
    },
    AssertGroupRowCount {
      group_index: 0,
      row_count: 0,
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn group_move_row_test() {
  let mut test = DatabaseGroupTest::new().await;
  let group = test.group_at_index(1).await;
  let scripts = vec![
    // Move the row at 0 in group0 to group1 at 1
    MoveRow {
      from_group_index: 1,
      from_row_index: 0,
      to_group_index: 1,
      to_row_index: 1,
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 2,
    },
    AssertRow {
      group_index: 1,
      row_index: 1,
      row: group.rows.first().unwrap().clone(),
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn group_move_row_to_other_group_test() {
  let mut test = DatabaseGroupTest::new().await;
  let group = test.group_at_index(1).await;
  let scripts = vec![
    MoveRow {
      from_group_index: 1,
      from_row_index: 0,
      to_group_index: 2,
      to_row_index: 1,
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 1,
    },
    AssertGroupRowCount {
      group_index: 2,
      row_count: 3,
    },
    AssertRow {
      group_index: 2,
      row_index: 1,
      row: group.rows.first().unwrap().clone(),
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn group_move_two_row_to_other_group_test() {
  let mut test = DatabaseGroupTest::new().await;
  let group_1 = test.group_at_index(1).await;
  let scripts = vec![
    // Move row at index 0 from group 1 to group 2 at index 1
    MoveRow {
      from_group_index: 1,
      from_row_index: 0,
      to_group_index: 2,
      to_row_index: 1,
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 1,
    },
    AssertGroupRowCount {
      group_index: 2,
      row_count: 3,
    },
    AssertRow {
      group_index: 2,
      row_index: 1,
      row: group_1.rows.first().unwrap().clone(),
    },
  ];
  test.run_scripts(scripts).await;

  let group_1 = test.group_at_index(1).await;
  // Move row at index 0 from group 1 to group 2 at index 1
  let scripts = vec![
    MoveRow {
      from_group_index: 1,
      from_row_index: 0,
      to_group_index: 2,
      to_row_index: 1,
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 0,
    },
    AssertGroupRowCount {
      group_index: 2,
      row_count: 4,
    },
    AssertRow {
      group_index: 2,
      row_index: 1,
      row: group_1.rows.first().unwrap().clone(),
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn group_move_row_to_other_group_and_reorder_from_up_to_down_test() {
  let mut test = DatabaseGroupTest::new().await;
  let group_1 = test.group_at_index(1).await;
  let group_2 = test.group_at_index(2).await;
  let scripts = vec![
    MoveRow {
      from_group_index: 1,
      from_row_index: 0,
      to_group_index: 2,
      to_row_index: 1,
    },
    AssertRow {
      group_index: 2,
      row_index: 1,
      row: group_1.rows.first().unwrap().clone(),
    },
  ];
  test.run_scripts(scripts).await;

  let scripts = vec![
    MoveRow {
      from_group_index: 2,
      from_row_index: 0,
      to_group_index: 2,
      to_row_index: 2,
    },
    AssertRow {
      group_index: 2,
      row_index: 2,
      row: group_2.rows.first().unwrap().clone(),
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn group_move_row_to_other_group_and_reorder_from_bottom_to_up_test() {
  let mut test = DatabaseGroupTest::new().await;
  let scripts = vec![MoveRow {
    from_group_index: 1,
    from_row_index: 0,
    to_group_index: 2,
    to_row_index: 1,
  }];
  test.run_scripts(scripts).await;

  let group = test.group_at_index(2).await;
  let scripts = vec![
    AssertGroupRowCount {
      group_index: 2,
      row_count: 3,
    },
    MoveRow {
      from_group_index: 2,
      from_row_index: 2,
      to_group_index: 2,
      to_row_index: 0,
    },
    AssertRow {
      group_index: 2,
      row_index: 0,
      row: group.rows.get(2).unwrap().clone(),
    },
  ];
  test.run_scripts(scripts).await;
}
#[tokio::test]
async fn group_create_row_test() {
  let mut test = DatabaseGroupTest::new().await;
  let scripts = vec![
    CreateRow { group_index: 1 },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 3,
    },
    CreateRow { group_index: 2 },
    CreateRow { group_index: 2 },
    AssertGroupRowCount {
      group_index: 2,
      row_count: 4,
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn group_delete_row_test() {
  let mut test = DatabaseGroupTest::new().await;
  let scripts = vec![
    DeleteRow {
      group_index: 1,
      row_index: 0,
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 1,
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn group_delete_all_row_test() {
  let mut test = DatabaseGroupTest::new().await;
  let scripts = vec![
    DeleteRow {
      group_index: 1,
      row_index: 0,
    },
    DeleteRow {
      group_index: 1,
      row_index: 0,
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 0,
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn group_update_row_test() {
  let mut test = DatabaseGroupTest::new().await;
  let scripts = vec![
    // Update the row at 0 in group0 by setting the row's group field data
    UpdateGroupedCell {
      from_group_index: 1,
      row_index: 0,
      to_group_index: 2,
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 1,
    },
    AssertGroupRowCount {
      group_index: 2,
      row_count: 3,
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn group_reorder_group_test() {
  let mut test = DatabaseGroupTest::new().await;
  let scripts = vec![
    // Update the row at 0 in group0 by setting the row's group field data
    UpdateGroupedCell {
      from_group_index: 1,
      row_index: 0,
      to_group_index: 2,
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 1,
    },
    AssertGroupRowCount {
      group_index: 2,
      row_count: 3,
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn group_move_to_default_group_test() {
  let mut test = DatabaseGroupTest::new().await;
  let scripts = vec![
    UpdateGroupedCell {
      from_group_index: 1,
      row_index: 0,
      to_group_index: 0,
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 1,
    },
    AssertGroupRowCount {
      group_index: 0,
      row_count: 1,
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn group_move_from_default_group_test() {
  let mut test = DatabaseGroupTest::new().await;
  // Move one row from group 1 to group 0
  let scripts = vec![
    UpdateGroupedCell {
      from_group_index: 1,
      row_index: 0,
      to_group_index: 0,
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 1,
    },
    AssertGroupRowCount {
      group_index: 0,
      row_count: 1,
    },
  ];
  test.run_scripts(scripts).await;

  // Move one row from group 0 to group 1
  let scripts = vec![
    UpdateGroupedCell {
      from_group_index: 0,
      row_index: 0,
      to_group_index: 1,
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 2,
    },
    AssertGroupRowCount {
      group_index: 0,
      row_count: 0,
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn group_move_group_test() {
  let mut test = DatabaseGroupTest::new().await;
  let group_0 = test.group_at_index(0).await;
  let group_1 = test.group_at_index(1).await;
  let scripts = vec![
    MoveGroup {
      from_group_index: 0,
      to_group_index: 1,
    },
    AssertGroupRowCount {
      group_index: 0,
      row_count: 2,
    },
    AssertGroup {
      group_index: 0,
      expected_group: group_1,
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 0,
    },
    AssertGroup {
      group_index: 1,
      expected_group: group_0,
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn group_move_group_row_after_move_group_test() {
  let mut test = DatabaseGroupTest::new().await;
  let group_1 = test.group_at_index(1).await;
  let group_2 = test.group_at_index(2).await;
  let scripts = vec![
    MoveGroup {
      from_group_index: 1,
      to_group_index: 2,
    },
    AssertGroup {
      group_index: 1,
      expected_group: group_2,
    },
    AssertGroup {
      group_index: 2,
      expected_group: group_1,
    },
    MoveRow {
      from_group_index: 1,
      from_row_index: 0,
      to_group_index: 2,
      to_row_index: 0,
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 1,
    },
    AssertGroupRowCount {
      group_index: 2,
      row_count: 3,
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn group_move_group_to_default_group_pos_test() {
  let mut test = DatabaseGroupTest::new().await;
  let group_0 = test.group_at_index(0).await;
  let group_3 = test.group_at_index(3).await;
  let scripts = vec![
    MoveGroup {
      from_group_index: 3,
      to_group_index: 0,
    },
    AssertGroup {
      group_index: 0,
      expected_group: group_3,
    },
    AssertGroup {
      group_index: 1,
      expected_group: group_0,
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn group_insert_single_select_option_test() {
  let mut test = DatabaseGroupTest::new().await;
  let new_option_name = "New option";
  let scripts = vec![
    AssertGroupCount(4),
    UpdateSingleSelectSelectOption {
      inserted_options: vec![SelectOption {
        id: new_option_name.to_string(),
        name: new_option_name.to_string(),
        color: Default::default(),
      }],
    },
    AssertGroupCount(5),
  ];
  test.run_scripts(scripts).await;
  let new_group = test.group_at_index(4).await;
  assert_eq!(new_group.group_id, new_option_name);
}

#[tokio::test]
async fn group_group_by_other_field() {
  let mut test = DatabaseGroupTest::new().await;
  let multi_select_field = test.get_multi_select_field().await;
  let scripts = vec![
    GroupByField {
      field_id: multi_select_field.id.clone(),
    },
    AssertGroupRowCount {
      group_index: 1,
      row_count: 3,
    },
    AssertGroupRowCount {
      group_index: 2,
      row_count: 2,
    },
    AssertGroupCount(4),
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn group_manual_create_new_group() {
  let mut test = DatabaseGroupTest::new().await;
  let new_group_name = "Resumed";
  let scripts = vec![
    AssertGroupCount(4),
    CreateGroup {
      name: new_group_name.to_string(),
    },
    AssertGroupCount(5),
  ];
  test.run_scripts(scripts).await;
}
