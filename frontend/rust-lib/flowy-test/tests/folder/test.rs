use flowy_folder2::entities::*;
use flowy_test::event_builder::EventBuilder;
use flowy_test::FlowyCoreTest;
use flowy_user::errors::ErrorCode;

#[tokio::test]
async fn create_workspace_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let request = CreateWorkspacePayloadPB {
    name: "my second workspace".to_owned(),
    desc: "".to_owned(),
  };
  let resp = EventBuilder::new(test)
    .event(flowy_folder2::event_map::FolderEvent::CreateWorkspace)
    .payload(request)
    .async_send()
    .await
    .parse::<flowy_folder2::entities::WorkspacePB>();
  assert_eq!(resp.name, "my second workspace");
}

#[tokio::test]
async fn open_workspace_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let payload = CreateWorkspacePayloadPB {
    name: "my second workspace".to_owned(),
    desc: "".to_owned(),
  };
  // create a workspace
  let resp_1 = EventBuilder::new(test.clone())
    .event(flowy_folder2::event_map::FolderEvent::CreateWorkspace)
    .payload(payload)
    .async_send()
    .await
    .parse::<flowy_folder2::entities::WorkspacePB>();

  // open the workspace
  let payload = WorkspaceIdPB {
    value: Some(resp_1.id.clone()),
  };
  let resp_2 = EventBuilder::new(test)
    .event(flowy_folder2::event_map::FolderEvent::OpenWorkspace)
    .payload(payload)
    .async_send()
    .await
    .parse::<flowy_folder2::entities::WorkspacePB>();

  assert_eq!(resp_1.id, resp_2.id);
  assert_eq!(resp_1.name, resp_2.name);
}

#[tokio::test]
async fn create_view_event_test() {
  let test = FlowyCoreTest::new_with_user().await;

  test.workspace().await;
  let payload = CreateViewPayloadPB {
    parent_view_id: "".to_string(),
    name: "".to_string(),
    desc: "".to_string(),
    thumbnail: None,
    layout: Default::default(),
    initial_data: vec![],
    meta: Default::default(),
    set_as_current: false,
  };
  // create a workspace
  let resp_1 = EventBuilder::new(test.clone())
    .event(flowy_folder2::event_map::FolderEvent::CreateView)
    .payload(payload)
    .async_send()
    .await
    .parse::<flowy_folder2::entities::WorkspacePB>();

  // open the workspace
  let payload = WorkspaceIdPB {
    value: Some(resp_1.id.clone()),
  };
  let resp_2 = EventBuilder::new(test)
    .event(flowy_folder2::event_map::FolderEvent::OpenWorkspace)
    .payload(payload)
    .async_send()
    .await
    .parse::<flowy_folder2::entities::WorkspacePB>();

  assert_eq!(resp_1.id, resp_2.id);
  assert_eq!(resp_1.name, resp_2.name);
}

#[tokio::test]
async fn create_parent_view_with_invalid_name() {
  for (name, code) in invalid_workspace_name_test_case() {
    let sdk = FlowyCoreTest::new();
    let request = CreateWorkspacePayloadPB {
      name,
      desc: "".to_owned(),
    };
    assert_eq!(
      EventBuilder::new(sdk)
        .event(flowy_folder2::event_map::FolderEvent::CreateWorkspace)
        .payload(request)
        .async_send()
        .await
        .error()
        .unwrap()
        .code,
      code.value()
    )
  }
}

fn invalid_workspace_name_test_case() -> Vec<(String, ErrorCode)> {
  vec![
    ("".to_owned(), ErrorCode::WorkspaceNameInvalid),
    ("1234".repeat(100), ErrorCode::WorkspaceNameTooLong),
  ]
}
