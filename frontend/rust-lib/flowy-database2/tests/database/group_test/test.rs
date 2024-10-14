use crate::database::group_test::script::DatabaseGroupTest;
use collab_database::fields::select_type_option::SelectOption;

#[tokio::test]
async fn group_init_test() {
  let mut test = DatabaseGroupTest::new().await;
  test.assert_group_count(4).await;
  test.assert_group_row_count(1, 2).await;
  test.assert_group_row_count(2, 2).await;
  test.assert_group_row_count(3, 1).await;
  test.assert_group_row_count(0, 0).await;
}

#[tokio::test]
async fn group_move_row_test() {
  let mut test = DatabaseGroupTest::new().await;
  let group = test.group_at_index(1).await;

  test.move_row(1, 0, 1, 1).await;
  test.assert_group_row_count(1, 2).await;
  test
    .assert_row(1, 1, group.rows.first().unwrap().clone())
    .await;
}

#[tokio::test]
async fn test_row_movement_between_groups_with_assertions() {
  let mut test = DatabaseGroupTest::new().await;
  for _ in 0..5 {
    test.move_row(1, 0, 2, 1).await;
    test.assert_group_row_count(1, 1).await;
    test.assert_group_row_count(2, 3).await;

    // Move the row back to the original group
    test.move_row(2, 1, 1, 0).await;
    test.assert_group_row_count(2, 2).await;
    test.assert_group_row_count(1, 2).await;

    tokio::time::sleep(tokio::time::Duration::from_millis(500)).await;
  }
}

#[tokio::test]
async fn group_move_two_row_to_other_group_test() {
  let mut test = DatabaseGroupTest::new().await;
  let group_1 = test.group_at_index(1).await;

  test.move_row(1, 0, 2, 1).await;
  test.assert_group_row_count(1, 1).await;
  test.assert_group_row_count(2, 3).await;
  test
    .assert_row(2, 1, group_1.rows.first().unwrap().clone())
    .await;

  let group_1 = test.group_at_index(1).await;
  test.move_row(1, 0, 2, 1).await;
  test.assert_group_row_count(1, 0).await;
  test.assert_group_row_count(2, 4).await;
  test
    .assert_row(2, 1, group_1.rows.first().unwrap().clone())
    .await;
}

#[tokio::test]
async fn group_move_row_to_other_group_and_reorder_from_up_to_down_test() {
  let mut test = DatabaseGroupTest::new().await;
  let group_1 = test.group_at_index(1).await;
  let group_2 = test.group_at_index(2).await;

  test.move_row(1, 0, 2, 1).await;
  test
    .assert_row(2, 1, group_1.rows.first().unwrap().clone())
    .await;

  test.move_row(2, 0, 2, 2).await;
  test
    .assert_row(2, 2, group_2.rows.first().unwrap().clone())
    .await;
}

#[tokio::test]
async fn group_move_row_to_other_group_and_reorder_from_bottom_to_up_test() {
  let mut test = DatabaseGroupTest::new().await;
  test.move_row(1, 0, 2, 1).await;

  let group = test.group_at_index(2).await;
  test.assert_group_row_count(2, 3).await;

  test.move_row(2, 2, 2, 0).await;
  test
    .assert_row(2, 0, group.rows.get(2).unwrap().clone())
    .await;
}

#[tokio::test]
async fn group_create_row_test() {
  let mut test = DatabaseGroupTest::new().await;
  test.create_row(1).await;
  test.assert_group_row_count(1, 3).await;

  test.create_row(2).await;
  test.create_row(2).await;
  test.assert_group_row_count(2, 4).await;
}

#[tokio::test]
async fn group_delete_row_test() {
  let mut test = DatabaseGroupTest::new().await;
  test.delete_row(1, 0).await;
  test.assert_group_row_count(1, 1).await;
}

#[tokio::test]
async fn group_delete_all_row_test() {
  let mut test = DatabaseGroupTest::new().await;
  test.delete_row(1, 0).await;
  test.delete_row(1, 0).await;
  test.assert_group_row_count(1, 0).await;
}

#[tokio::test]
async fn group_update_row_test() {
  let mut test = DatabaseGroupTest::new().await;
  test.update_grouped_cell(1, 0, 2).await;
  test.assert_group_row_count(1, 1).await;
  test.assert_group_row_count(2, 3).await;
}

#[tokio::test]
async fn group_reorder_group_test() {
  let mut test = DatabaseGroupTest::new().await;
  test.update_grouped_cell(1, 0, 2).await;
  test.assert_group_row_count(1, 1).await;
  test.assert_group_row_count(2, 3).await;
}

#[tokio::test]
async fn group_move_to_default_group_test() {
  let mut test = DatabaseGroupTest::new().await;
  test.update_grouped_cell(1, 0, 0).await;
  test.assert_group_row_count(1, 1).await;
  test.assert_group_row_count(0, 1).await;
}

#[tokio::test]
async fn group_move_from_default_group_test() {
  let mut test = DatabaseGroupTest::new().await;
  test.update_grouped_cell(1, 0, 0).await;
  test.assert_group_row_count(1, 1).await;
  test.assert_group_row_count(0, 1).await;

  test.update_grouped_cell(0, 0, 1).await;
  test.assert_group_row_count(1, 2).await;
  test.assert_group_row_count(0, 0).await;
}

#[tokio::test]
async fn group_move_group_test() {
  let mut test = DatabaseGroupTest::new().await;
  let group_0 = test.group_at_index(0).await;
  let group_1 = test.group_at_index(1).await;

  test.move_group(0, 1).await;
  test.assert_group_row_count(0, 2).await;
  test.assert_group(0, group_1).await;
  test.assert_group_row_count(1, 0).await;
  test.assert_group(1, group_0).await;
}

#[tokio::test]
async fn group_move_group_row_after_move_group_test() {
  let mut test = DatabaseGroupTest::new().await;
  let group_1 = test.group_at_index(1).await;
  let group_2 = test.group_at_index(2).await;

  test.move_group(1, 2).await;
  test.assert_group(1, group_2).await;
  test.assert_group(2, group_1).await;

  test.move_row(1, 0, 2, 0).await;
  test.assert_group_row_count(1, 1).await;
  test.assert_group_row_count(2, 3).await;
}

#[tokio::test]
async fn group_move_group_to_default_group_pos_test() {
  let mut test = DatabaseGroupTest::new().await;
  let group_0 = test.group_at_index(0).await;
  let group_3 = test.group_at_index(3).await;

  test.move_group(3, 0).await;
  test.assert_group(0, group_3).await;
  test.assert_group(1, group_0).await;
}

#[tokio::test]
async fn group_insert_single_select_option_test() {
  let mut test = DatabaseGroupTest::new().await;
  let new_option_name = "New option";

  test.assert_group_count(4).await;
  test
    .update_single_select_option(vec![SelectOption {
      id: new_option_name.to_string(),
      name: new_option_name.to_string(),
      color: Default::default(),
    }])
    .await;

  test.assert_group_count(5).await;
  let new_group = test.group_at_index(4).await;
  assert_eq!(new_group.group_id, new_option_name);
}

#[tokio::test]
async fn group_group_by_other_field() {
  let mut test = DatabaseGroupTest::new().await;
  let multi_select_field = test.get_multi_select_field().await;

  test.group_by_field(&multi_select_field.id).await;
  test.assert_group_row_count(1, 3).await;
  test.assert_group_row_count(2, 2).await;
  test.assert_group_count(4).await;
}

#[tokio::test]
async fn group_manual_create_new_group() {
  let mut test = DatabaseGroupTest::new().await;
  let new_group_name = "Resumed";

  test.assert_group_count(4).await;
  test.create_group(new_group_name).await;
  test.assert_group_count(5).await;
}
