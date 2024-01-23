use collab_folder::ViewLayout;

use flowy_folder::entities::icon::{ViewIconPB, ViewIconTypePB};

use crate::folder::local_test::script::FolderScript::*;
use crate::folder::local_test::script::FolderTest;

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
        is_favorite: None,
      },
      ReloadParentView(parent_view.id),
    ])
    .await;
  assert_eq!(test.parent_view.name, new_name);
}

#[tokio::test]
async fn create_sub_views_test() {
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
        is_favorite: None,
      },
      ReadView(view.id),
    ])
    .await;
  assert_eq!(test.child_view.name, new_name);
}

#[tokio::test]
async fn view_icon_update_test() {
  let mut test = FolderTest::new().await;
  let view = test.child_view.clone();
  let new_icon = ViewIconPB {
    ty: ViewIconTypePB::Emoji,
    value: "👍".to_owned(),
  };
  assert!(view.icon.is_none());
  test
    .run_scripts(vec![
      UpdateViewIcon {
        icon: Some(new_icon.clone()),
      },
      ReadView(view.id.clone()),
    ])
    .await;

  assert_eq!(test.child_view.icon, Some(new_icon));

  test
    .run_scripts(vec![UpdateViewIcon { icon: None }, ReadView(view.id)])
    .await;
  assert_eq!(test.child_view.icon, None);
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

#[tokio::test]
async fn toggle_favorites() {
  let mut test = FolderTest::new().await;
  let view = test.child_view.clone();
  test
    .run_scripts(vec![
      ReadView(view.id.clone()),
      ToggleFavorite,
      ReadFavorites,
      ReadView(view.id.clone()),
    ])
    .await;
  assert!(test.child_view.is_favorite);
  assert_ne!(test.favorites.len(), 0);
  assert_eq!(test.favorites[0].id, view.id);

  let view = test.child_view.clone();
  test
    .run_scripts(vec![
      ReadView(view.id.clone()),
      ToggleFavorite,
      ReadFavorites,
      ReadView(view.id.clone()),
    ])
    .await;

  assert!(!test.child_view.is_favorite);
  assert!(test.favorites.is_empty());
}

#[tokio::test]
async fn delete_favorites() {
  let mut test = FolderTest::new().await;
  let view = test.child_view.clone();
  test
    .run_scripts(vec![
      ReadView(view.id.clone()),
      ToggleFavorite,
      ReadFavorites,
      ReadView(view.id.clone()),
    ])
    .await;
  assert!(test.child_view.is_favorite);
  assert_ne!(test.favorites.len(), 0);
  assert_eq!(test.favorites[0].id, view.id);

  test.run_scripts(vec![DeleteView, ReadFavorites]).await;
  assert_eq!(test.favorites.len(), 0);
}

#[tokio::test]
async fn move_view_event_test() {
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
  let move_view_id = view_ids[0].clone();
  let new_prev_view_id = view_ids[1].clone();
  let new_parent_view_id = parent_view.id.clone();
  test
    .run_scripts(vec![
      MoveView {
        view_id: move_view_id.clone(),
        new_parent_id: new_parent_view_id.clone(),
        prev_view_id: Some(new_prev_view_id.clone()),
      },
      ReloadParentView(parent_view.id.clone()),
    ])
    .await;

  let after_view_ids = test
    .parent_view
    .child_views
    .iter()
    .map(|view| view.id.clone())
    .collect::<Vec<String>>();
  assert_eq!(after_view_ids[0], view_ids[1]);
  assert_eq!(after_view_ids[1], view_ids[0]);
}
