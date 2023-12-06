use event_integration::EventIntegrationTest;

// The number of groups should be 0 if there is no group by field in grid
#[tokio::test]
async fn get_groups_event_with_grid_test() {
  let test = EventIntegrationTest::new_with_guest_user().await;
  let current_workspace = test.get_current_workspace().await;
  let grid_view = test
    .create_grid(&current_workspace.id, "my board view".to_owned(), vec![])
    .await;

  let groups = test.get_groups(&grid_view.id).await;
  assert_eq!(groups.len(), 0);
}

#[tokio::test]
async fn get_groups_event_test() {
  let test = EventIntegrationTest::new_with_guest_user().await;
  let current_workspace = test.get_current_workspace().await;
  let board_view = test
    .create_board(&current_workspace.id, "my board view".to_owned(), vec![])
    .await;

  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups.len(), 4);
}

#[tokio::test]
async fn move_group_event_test() {
  let test = EventIntegrationTest::new_with_guest_user().await;
  let current_workspace = test.get_current_workspace().await;
  let board_view = test
    .create_board(&current_workspace.id, "my board view".to_owned(), vec![])
    .await;

  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups.len(), 4);
  let group_1 = groups[0].group_id.clone();
  let group_2 = groups[1].group_id.clone();
  let group_3 = groups[2].group_id.clone();
  let group_4 = groups[3].group_id.clone();

  let error = test.move_group(&board_view.id, &group_2, &group_3).await;
  assert!(error.is_none());

  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups[0].group_id, group_1);
  assert_eq!(groups[1].group_id, group_3);
  assert_eq!(groups[2].group_id, group_2);
  assert_eq!(groups[3].group_id, group_4);

  let error = test.move_group(&board_view.id, &group_1, &group_4).await;
  assert!(error.is_none());

  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups[0].group_id, group_3);
  assert_eq!(groups[1].group_id, group_2);
  assert_eq!(groups[2].group_id, group_4);
  assert_eq!(groups[3].group_id, group_1);
}

#[tokio::test]
async fn move_group_event_with_invalid_id_test() {
  let test = EventIntegrationTest::new_with_guest_user().await;
  let current_workspace = test.get_current_workspace().await;
  let board_view = test
    .create_board(&current_workspace.id, "my board view".to_owned(), vec![])
    .await;

  // Empty to group id
  let groups = test.get_groups(&board_view.id).await;
  let error = test
    .move_group(&board_view.id, &groups[0].group_id, "")
    .await;
  assert!(error.is_some());

  // empty from group id
  let error = test
    .move_group(&board_view.id, "", &groups[1].group_id)
    .await;
  assert!(error.is_some());
}

#[tokio::test]
async fn rename_group_event_test() {
  let test = EventIntegrationTest::new_with_guest_user().await;
  let current_workspace = test.get_current_workspace().await;
  let board_view = test
    .create_board(&current_workspace.id, "my board view".to_owned(), vec![])
    .await;

  // Empty to group id
  let groups = test.get_groups(&board_view.id).await;
  let error = test
    .update_group(
      &board_view.id,
      &groups[1].group_id,
      &groups[1].field_id,
      Some("new name".to_owned()),
      None,
    )
    .await;
  assert!(error.is_none());

  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups[1].group_name, "new name".to_owned());
}

#[tokio::test]
async fn hide_group_event_test() {
  let test = EventIntegrationTest::new_with_guest_user().await;
  let current_workspace = test.get_current_workspace().await;
  let board_view = test
    .create_board(&current_workspace.id, "my board view".to_owned(), vec![])
    .await;

  // Empty to group id
  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups.len(), 4);

  let error = test
    .update_group(
      &board_view.id,
      &groups[0].group_id,
      &groups[0].field_id,
      None,
      Some(false),
    )
    .await;
  assert!(error.is_none());

  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups.len(), 4);
  assert_eq!(groups[0].is_visible, false);
}

#[tokio::test]
async fn update_group_name_test() {
  let test = EventIntegrationTest::new_with_guest_user().await;
  let current_workspace = test.get_current_workspace().await;
  let board_view = test
    .create_board(&current_workspace.id, "my board view".to_owned(), vec![])
    .await;

  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups.len(), 4);
  assert_eq!(groups[1].group_name, "To Do");
  assert_eq!(groups[2].group_name, "Doing");
  assert_eq!(groups[3].group_name, "Done");

  test
    .update_group(
      &board_view.id,
      &groups[1].group_id,
      &groups[1].field_id,
      Some("To Do?".to_string()),
      None,
    )
    .await;

  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups.len(), 4);
  assert_eq!(groups[1].group_name, "To Do?");
  assert_eq!(groups[2].group_name, "Doing");
}

#[tokio::test]
async fn delete_group_test() {
  let test = EventIntegrationTest::new_with_guest_user().await;
  let current_workspace = test.get_current_workspace().await;
  let board_view = test
    .create_board(&current_workspace.id, "my board view".to_owned(), vec![])
    .await;

  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups.len(), 4);
  assert_eq!(groups[1].group_name, "To Do");
  assert_eq!(groups[2].group_name, "Doing");
  assert_eq!(groups[3].group_name, "Done");

  test.delete_group(&board_view.id, &groups[1].group_id).await;

  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups.len(), 3);
  assert_eq!(groups[1].group_name, "Doing");
  assert_eq!(groups[2].group_name, "Done");
}
