use crate::script::{invalid_workspace_name_test_case, FolderScript::*, FolderTest};
use collab_folder::core::ViewLayout;
use flowy_folder2::entities::CreateWorkspacePayloadPB;
use flowy_test::{event_builder::*, FlowySDKTest};

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

  let app = test.app.clone();
  test.run_scripts(vec![ReadApp(app.id)]).await;
}

#[tokio::test]
async fn workspace_create_with_invalid_name() {
  for (name, code) in invalid_workspace_name_test_case() {
    let sdk = FlowySDKTest::default();
    let request = CreateWorkspacePayloadPB {
      name,
      desc: "".to_owned(),
    };
    assert_eq!(
      Folder2EventBuilder::new(sdk)
        .event(flowy_folder2::event_map::FolderEvent::CreateWorkspace)
        .payload(request)
        .async_send()
        .await
        .error()
        .code,
      code.value()
    )
  }
}

#[tokio::test]
#[should_panic]
async fn app_delete() {
  let mut test = FolderTest::new().await;
  let app = test.app.clone();
  test.run_scripts(vec![DeleteApp, ReadApp(app.id)]).await;
}

#[tokio::test]
async fn app_delete_then_restore() {
  let mut test = FolderTest::new().await;
  let app = test.app.clone();
  test
    .run_scripts(vec![
      DeleteApp,
      RestoreAppFromTrash,
      ReadApp(app.id.clone()),
      AssertApp(app),
    ])
    .await;
}

#[tokio::test]
async fn app_read() {
  let mut test = FolderTest::new().await;
  let app = test.app.clone();
  test
    .run_scripts(vec![ReadApp(app.id.clone()), AssertApp(app)])
    .await;
}

#[tokio::test]
async fn app_update() {
  let mut test = FolderTest::new().await;
  let app = test.app.clone();
  let new_name = "😁 hell world".to_owned();
  assert_ne!(app.name, new_name);

  test
    .run_scripts(vec![
      UpdateApp {
        name: Some(new_name.clone()),
        desc: None,
      },
      ReadApp(app.id),
    ])
    .await;
  assert_eq!(test.app.name, new_name);
}

#[tokio::test]
async fn app_create_with_view() {
  let mut test = FolderTest::new().await;
  let mut app = test.app.clone();
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
      ReadApp(app.id),
    ])
    .await;

  app = test.app.clone();
  assert_eq!(app.belongings.len(), 3);
  assert_eq!(app.belongings[1].name, "View A");
  assert_eq!(app.belongings[2].name, "Grid")
}

#[tokio::test]
async fn view_update() {
  let mut test = FolderTest::new().await;
  let view = test.view.clone();
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
  assert_eq!(test.view.name, new_name);
}

#[tokio::test]
#[should_panic]
async fn view_delete() {
  let mut test = FolderTest::new().await;
  let view = test.view.clone();
  test.run_scripts(vec![DeleteView, ReadView(view.id)]).await;
}

#[tokio::test]
async fn view_delete_then_restore() {
  let mut test = FolderTest::new().await;
  let view = test.view.clone();
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
  let app = test.app.clone();
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
      ReadApp(app.id.clone()),
    ])
    .await;

  assert_eq!(test.app.belongings.len(), 3);
  let view_ids = test
    .app
    .belongings
    .iter()
    .map(|view| view.id.clone())
    .collect::<Vec<String>>();
  test
    .run_scripts(vec![DeleteViews(view_ids), ReadApp(app.id), ReadTrash])
    .await;

  assert_eq!(test.app.belongings.len(), 0);
  assert_eq!(test.trash.len(), 3);
}

#[tokio::test]
async fn view_delete_all_permanent() {
  let mut test = FolderTest::new().await;
  let app = test.app.clone();
  test
    .run_scripts(vec![
      CreateView {
        name: "View A".to_owned(),
        desc: "View A description".to_owned(),
        layout: ViewLayout::Document,
      },
      ReadApp(app.id.clone()),
    ])
    .await;

  let view_ids = test
    .app
    .belongings
    .iter()
    .map(|view| view.id.clone())
    .collect::<Vec<String>>();
  test
    .run_scripts(vec![
      DeleteViews(view_ids),
      ReadApp(app.id),
      DeleteAllTrash,
      ReadTrash,
    ])
    .await;

  assert_eq!(test.app.belongings.len(), 0);
  assert_eq!(test.trash.len(), 0);
}
