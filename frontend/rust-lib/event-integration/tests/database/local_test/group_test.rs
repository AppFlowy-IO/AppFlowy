use event_integration::EventIntegrationTest;

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
