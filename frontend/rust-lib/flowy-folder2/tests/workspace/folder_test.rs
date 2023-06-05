use crate::script::{invalid_workspace_name_test_case, FolderScript::*, FolderTest};
use collab_folder::core::ViewLayout;
use flowy_folder2::entities::CreateWorkspacePayloadPB;
use flowy_test::{event_builder::*, FlowyCoreTest};

#[tokio::test]
async fn workspace_read_all() {
  let mut test = FolderTest::new().await;
  test.run_scripts(vec![ReadAllWorkspaces]).await;
  assert!(!test.all_workspace.is_empty());
}

#[tokio::test]
async fn workspace_create() {
  let mut test = FolderTest::new().await;
  let name = "My new workspace".to_owned();
  let desc = "Daily routines".to_owned();
  test
    .run_scripts(vec![CreateWorkspace {
      name: name.clone(),
      desc: desc.clone(),
    }])
    .await;

  let workspace = test.workspace.clone();
  assert_eq!(workspace.name, name);

  test
    .run_scripts(vec![
      ReadWorkspace(Some(workspace.id.clone())),
      AssertWorkspace(workspace),
    ])
    .await;
}

#[tokio::test]
async fn workspace_read() {
  let mut test = FolderTest::new().await;
  let workspace = test.workspace.clone();

  test
    .run_scripts(vec![
      ReadWorkspace(Some(workspace.id.clone())),
      AssertWorkspace(workspace),
    ])
    .await;
}

#[tokio::test]
async fn workspace_create_with_apps() {
  let mut test = FolderTest::new().await;
  test
    .run_scripts(vec![CreateApp {
      name: "App".to_string(),
      desc: "App description".to_string(),
    }])
    .await;

  let app = test.parent_view.clone();
  test.run_scripts(vec![RefreshRootView(app.id)]).await;
}
<<<<<<< Updated upstream

#[tokio::test]
async fn workspace_create_with_invalid_name() {
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

=======
>>>>>>> Stashed changes
#[tokio::test]
#[should_panic]
async fn app_delete() {
  let mut test = FolderTest::new().await;
  let app = test.parent_view.clone();
  test
    .run_scripts(vec![DeleteRootView, RefreshRootView(app.id)])
    .await;
}

#[tokio::test]
async fn app_delete_then_restore() {
  let mut test = FolderTest::new().await;
  test
    .run_scripts(vec![RefreshRootView(test.parent_view.id.clone())])
    .await;

  let parent_view = test.parent_view.clone();
  test
    .run_scripts(vec![
      DeleteRootView,
      RestoreAppFromTrash,
      RefreshRootView(parent_view.id.clone()),
      AssertRootView(parent_view),
    ])
    .await;
}

#[tokio::test]
async fn app_update() {
  let mut test = FolderTest::new().await;
  let app = test.parent_view.clone();
  let new_name = "😁 hell world".to_owned();
  assert_ne!(app.name, new_name);

  test
    .run_scripts(vec![
      UpdateRootView {
        name: Some(new_name.clone()),
        desc: None,
      },
      RefreshRootView(app.id),
    ])
    .await;
  assert_eq!(test.parent_view.name, new_name);
}

#[tokio::test]
async fn app_create_with_view() {
  let mut test = FolderTest::new().await;
  let mut app = test.parent_view.clone();
  test
    .run_scripts(vec![
      CreateView {
        name: "View A".to_owned(),
        desc: "View A description".to_owned(),
        layout: ViewLayout::Document,
      },
      CreateView {
        name: "Grid".to_owned(),
        desc: "Grid description".to_owned(),
        layout: ViewLayout::Grid,
      },
      RefreshRootView(app.id),
    ])
    .await;

  app = test.parent_view.clone();
  assert_eq!(app.child_views.len(), 3);
  assert_eq!(app.child_views[1].name, "View A");
  assert_eq!(app.child_views[2].name, "Grid")
}

#[tokio::test]
async fn view_update() {
  let mut test = FolderTest::new().await;
  let view = test.child_view.clone();
  let new_name = "😁 123".to_owned();
  assert_ne!(view.name, new_name);

  test
    .run_scripts(vec![
      UpdateView {
        name: Some(new_name.clone()),
        desc: None,
      },
      ReadView(view.id),
    ])
    .await;
  assert_eq!(test.child_view.name, new_name);
}

#[tokio::test]
#[should_panic]
async fn view_delete() {
  let mut test = FolderTest::new().await;
  let view = test.child_view.clone();
  test.run_scripts(vec![DeleteView, ReadView(view.id)]).await;
}

#[tokio::test]
async fn view_delete_then_restore() {
  let mut test = FolderTest::new().await;
  let view = test.child_view.clone();
  test
    .run_scripts(vec![
      DeleteView,
      RestoreViewFromTrash,
      ReadView(view.id.clone()),
      AssertView(view),
    ])
    .await;
}

#[tokio::test]
async fn view_delete_all() {
  let mut test = FolderTest::new().await;
  let parent_view = test.parent_view.clone();
  test
    .run_scripts(vec![
      CreateView {
        name: "View A".to_owned(),
        desc: "View A description".to_owned(),
        layout: ViewLayout::Document,
      },
      CreateView {
        name: "Grid".to_owned(),
        desc: "Grid description".to_owned(),
        layout: ViewLayout::Grid,
      },
      RefreshRootView(parent_view.id.clone()),
    ])
    .await;

  assert_eq!(
    test.parent_view.child_views.len(),
    3,
    "num of belongings should be 3"
  );
  let view_ids = test
    .parent_view
    .child_views
    .iter()
    .map(|view| view.id.clone())
    .collect::<Vec<String>>();
  test
    .run_scripts(vec![
      DeleteViews(view_ids),
      RefreshRootView(parent_view.id),
      ReadTrash,
    ])
    .await;

  assert_eq!(test.parent_view.child_views.len(), 0);
  assert_eq!(test.trash.len(), 3);
}

#[tokio::test]
async fn view_delete_all_permanent() {
  let mut test = FolderTest::new().await;
  let app = test.parent_view.clone();
  test
    .run_scripts(vec![
      CreateView {
        name: "View A".to_owned(),
        desc: "View A description".to_owned(),
        layout: ViewLayout::Document,
      },
      RefreshRootView(app.id.clone()),
    ])
    .await;

  let view_ids = test
    .parent_view
    .child_views
    .iter()
    .map(|view| view.id.clone())
    .collect::<Vec<String>>();
  test
    .run_scripts(vec![
      DeleteViews(view_ids),
      RefreshRootView(app.id),
      DeleteAllTrash,
      ReadTrash,
    ])
    .await;

  assert_eq!(test.parent_view.child_views.len(), 0);
  assert_eq!(test.trash.len(), 0);
}
