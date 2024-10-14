use crate::database::group_test::script::DatabaseGroupTest;

#[tokio::test]
async fn group_group_by_url() {
  let mut test = DatabaseGroupTest::new().await;
  let url_field = test.get_url_field().await;

  // Group by URL field
  test.group_by_field(&url_field.id).await;

  // Check group row counts
  test.assert_group_row_count(0, 2).await; // No status group
  test.assert_group_row_count(1, 2).await; // https://appflowy.io group
  test.assert_group_row_count(2, 1).await; // https://github.com/AppFlowy-IO/AppFlowy group
  test.assert_group_count(3).await;
}

#[tokio::test]
async fn group_alter_url_to_another_group_url_test() {
  let mut test = DatabaseGroupTest::new().await;
  let url_field = test.get_url_field().await;

  // Group by URL field
  test.group_by_field(&url_field.id).await;

  // Check initial group row counts
  test.assert_group_row_count(0, 2).await; // No status group
  test.assert_group_row_count(1, 2).await; // https://appflowy.io group
  test.assert_group_row_count(2, 1).await; // https://github.com/AppFlowy-IO/AppFlowy group

  // Move the last row from group 2 to group 1
  test.update_grouped_cell(2, 0, 1).await;

  // Verify group counts after moving
  test.assert_group_count(2).await;
}

#[tokio::test]
async fn group_alter_url_to_new_url_test() {
  let mut test = DatabaseGroupTest::new().await;
  let url_field = test.get_url_field().await;

  // Group by URL field
  test.group_by_field(&url_field.id).await;

  // Change the URL of a row to a new value
  test
    .update_grouped_cell_with_data(0, 0, "https://github.com/AppFlowy-IO".to_string())
    .await;

  // Verify group row counts after URL update
  test.assert_group_row_count(0, 1).await; // No status group
  test.assert_group_row_count(1, 2).await; // https://appflowy.io group
  test.assert_group_row_count(2, 1).await; // https://github.com/AppFlowy-IO/AppFlowy group
  test.assert_group_row_count(3, 1).await; // https://github.com/AppFlowy-IO group
  test.assert_group_count(4).await;
}

#[tokio::test]
async fn group_move_url_group_row_test() {
  let mut test = DatabaseGroupTest::new().await;
  let url_field = test.get_url_field().await;

  // Group by URL field
  test.group_by_field(&url_field.id).await;

  // Check initial group row counts
  test.assert_group_row_count(0, 2).await; // No status group
  test.assert_group_row_count(1, 2).await; // https://appflowy.io group
  test.assert_group_row_count(2, 1).await; // https://github.com/AppFlowy-IO/AppFlowy group
  test.assert_group_count(3).await;

  // Move a row from one group to another
  test.move_row(0, 0, 1, 0).await;

  // Verify row counts after the move
  test.assert_group_row_count(0, 1).await;
  test.assert_group_row_count(1, 3).await;
  test.assert_group_row_count(2, 1).await;
}
