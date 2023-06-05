use crate::script::{FolderScript::*, FolderTest};
use collab_folder::core::ViewLayout;

#[tokio::test]
async fn read_all_workspace_test() {
  let mut test = FolderTest::new().await;
  test.run_scripts(vec![ReadAllWorkspaces]).await;
  assert!(!test.all_workspace.is_empty());
}

#[tokio::test]
async fn create_workspace_test() {
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
async fn get_workspace_test() {
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
async fn create_parent_view_test() {
  let mut test = FolderTest::new().await;
  test
    .run_scripts(vec![CreateParentView {
      name: "App".to_string(),
      desc: "App description".to_string(),
    }])
    .await;

  let app = test.parent_view.clone();
  test.run_scripts(vec![ReloadParentView(app.id)]).await;
}

#[tokio::test]
#[should_panic]
async fn delete_parent_view_test() {
  let mut test = FolderTest::new().await;
  let parent_view = test.parent_view.clone();
  test
    .run_scripts(vec![DeleteParentView, ReloadParentView(parent_view.id)])
    .await;
}

#[tokio::test]
async fn delete_parent_view_then_restore() {
  let mut test = FolderTest::new().await;
  test
    .run_scripts(vec![ReloadParentView(test.parent_view.id.clone())])
    .await;

  let parent_view = test.parent_view.clone();
  test
    .run_scripts(vec![
      DeleteParentView,
      RestoreAppFromTrash,
      ReloadParentView(parent_view.id.clone()),
      AssertParentView(parent_view),
    ])
    .await;
}

#[tokio::test]
async fn update_parent_view_test() {
  let mut test = FolderTest::new().await;
  let parent_view = test.parent_view.clone();
  let new_name = "😁 hell world".to_owned();
  assert_ne!(parent_view.name, new_name);

  test
    .run_scripts(vec![
      UpdateParentView {
        name: Some(new_name.clone()),
        desc: None,
      },
      ReloadParentView(parent_view.id),
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
      ReloadParentView(app.id),
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
      ReloadParentView(parent_view.id.clone()),
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
      ReloadParentView(parent_view.id),
      ReadTrash,
    ])
    .await;

  assert_eq!(test.parent_view.child_views.len(), 0);
  assert_eq!(test.trash.len(), 3);
}

#[tokio::test]
async fn view_delete_all_permanent() {
  let mut test = FolderTest::new().await;
  let parent_view = test.parent_view.clone();
  test
    .run_scripts(vec![
      CreateView {
        name: "View A".to_owned(),
        desc: "View A description".to_owned(),
        layout: ViewLayout::Document,
      },
      ReloadParentView(parent_view.id.clone()),
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
      ReloadParentView(parent_view.id),
      DeleteAllTrash,
      ReadTrash,
    ])
    .await;

  assert_eq!(test.parent_view.child_views.len(), 0);
  assert_eq!(test.trash.len(), 0);
}
