use event_integration::event_builder::EventBuilder;
use event_integration::EventIntegrationTest;
use flowy_folder::entities::icon::{UpdateViewIconPayloadPB, ViewIconPB, ViewIconTypePB};
use flowy_folder::entities::*;
use flowy_user::errors::ErrorCode;

#[tokio::test]
async fn create_workspace_event_test() {
  let test = EventIntegrationTest::new_anon().await;
  let request = CreateWorkspacePayloadPB {
    name: "my second workspace".to_owned(),
    desc: "".to_owned(),
  };
  let view_pb = EventBuilder::new(test)
    .event(flowy_folder::event_map::FolderEvent::CreateFolderWorkspace)
    .payload(request)
    .async_send()
    .await
    .parse::<flowy_folder::entities::ViewPB>();

  assert_eq!(view_pb.parent_view_id, "my second workspace".to_owned());
}

// #[tokio::test]
// async fn open_workspace_event_test() {
//   let test = EventIntegrationTest::new_with_guest_user().await;
//   let payload = CreateWorkspacePayloadPB {
//     name: "my second workspace".to_owned(),
//     desc: "".to_owned(),
//   };
//   // create a workspace
//   let resp_1 = EventBuilder::new(test.clone())
//     .event(flowy_folder::event_map::FolderEvent::CreateWorkspace)
//     .payload(payload)
//     .async_send()
//     .await
//     .parse::<flowy_folder::entities::WorkspacePB>();
//
//   // open the workspace
//   let payload = WorkspaceIdPB {
//     value: Some(resp_1.id.clone()),
//   };
//   let resp_2 = EventBuilder::new(test)
//     .event(flowy_folder::event_map::FolderEvent::OpenWorkspace)
//     .payload(payload)
//     .async_send()
//     .await
//     .parse::<flowy_folder::entities::WorkspacePB>();
//
//   assert_eq!(resp_1.id, resp_2.id);
//   assert_eq!(resp_1.name, resp_2.name);
// }

#[tokio::test]
async fn create_view_event_test() {
  let test = EventIntegrationTest::new_anon().await;
  let current_workspace = test.get_current_workspace().await;
  let view = test
    .create_view(&current_workspace.id, "My first view".to_string())
    .await;
  assert_eq!(view.parent_view_id, current_workspace.id);
  assert_eq!(view.name, "My first view");
  assert_eq!(view.layout, ViewLayoutPB::Document);
}

#[tokio::test]
async fn update_view_event_with_name_test() {
  let test = EventIntegrationTest::new_anon().await;
  let current_workspace = test.get_current_workspace().await;
  let view = test
    .create_view(&current_workspace.id, "My first view".to_string())
    .await;

  let error = test
    .update_view(UpdateViewPayloadPB {
      view_id: view.id.clone(),
      name: Some("My second view".to_string()),
      ..Default::default()
    })
    .await;
  assert!(error.is_none());

  let view = test.get_view(&view.id).await;
  assert_eq!(view.name, "My second view");
}

#[tokio::test]
async fn update_view_icon_event_test() {
  let test = EventIntegrationTest::new_anon().await;
  let current_workspace = test.get_current_workspace().await;
  let view = test
    .create_view(&current_workspace.id, "My first view".to_string())
    .await;

  let new_icon = ViewIconPB {
    ty: ViewIconTypePB::Emoji,
    value: "👍".to_owned(),
  };
  let error = test
    .update_view_icon(UpdateViewIconPayloadPB {
      view_id: view.id.clone(),
      icon: Some(new_icon.clone()),
    })
    .await;
  assert!(error.is_none());

  let view = test.get_view(&view.id).await;
  assert_eq!(view.icon, Some(new_icon));
}

#[tokio::test]
async fn delete_view_event_test() {
  let test = EventIntegrationTest::new_anon().await;
  let current_workspace = test.get_current_workspace().await;
  let view = test
    .create_view(&current_workspace.id, "My first view".to_string())
    .await;
  test.delete_view(&view.id).await;

  // Try the read the view
  let payload = ViewIdPB {
    value: view.id.clone(),
  };
  let error = EventBuilder::new(test.clone())
    .event(flowy_folder::event_map::FolderEvent::GetView)
    .payload(payload)
    .async_send()
    .await
    .error()
    .unwrap();
  assert_eq!(error.code, ErrorCode::RecordNotFound);
}

#[tokio::test]
async fn put_back_trash_event_test() {
  let test = EventIntegrationTest::new_anon().await;
  let current_workspace = test.get_current_workspace().await;
  let view = test
    .create_view(&current_workspace.id, "My first view".to_string())
    .await;
  test.delete_view(&view.id).await;

  // After delete view, the view will be moved to trash
  let payload = ViewIdPB {
    value: view.id.clone(),
  };
  let error = EventBuilder::new(test.clone())
    .event(flowy_folder::event_map::FolderEvent::GetView)
    .payload(payload)
    .async_send()
    .await
    .error()
    .unwrap();
  assert_eq!(error.code, ErrorCode::RecordNotFound);

  let payload = TrashIdPB {
    id: view.id.clone(),
  };
  EventBuilder::new(test.clone())
    .event(flowy_folder::event_map::FolderEvent::RestoreTrashItem)
    .payload(payload)
    .async_send()
    .await;

  let payload = ViewIdPB {
    value: view.id.clone(),
  };
  let error = EventBuilder::new(test.clone())
    .event(flowy_folder::event_map::FolderEvent::GetView)
    .payload(payload)
    .async_send()
    .await
    .error();
  assert!(error.is_none());
}

#[tokio::test]
async fn delete_view_permanently_event_test() {
  let test = EventIntegrationTest::new_anon().await;
  let current_workspace = test.get_current_workspace().await;
  let view = test
    .create_view(&current_workspace.id, "My first view".to_string())
    .await;
  let payload = RepeatedViewIdPB {
    items: vec![view.id.clone()],
  };

  // delete the view. the view will be moved to trash
  EventBuilder::new(test.clone())
    .event(flowy_folder::event_map::FolderEvent::DeleteView)
    .payload(payload)
    .async_send()
    .await;

  let trash = EventBuilder::new(test.clone())
    .event(flowy_folder::event_map::FolderEvent::ListTrashItems)
    .async_send()
    .await
    .parse::<flowy_folder::entities::RepeatedTrashPB>()
    .items;
  assert_eq!(trash.len(), 1);
  assert_eq!(trash[0].id, view.id);

  // delete the view from trash
  let payload = RepeatedTrashIdPB {
    items: vec![TrashIdPB {
      id: view.id.clone(),
    }],
  };
  EventBuilder::new(test.clone())
    .event(flowy_folder::event_map::FolderEvent::PermanentlyDeleteTrashItem)
    .payload(payload)
    .async_send()
    .await;

  // After delete the last view, the trash should be empty
  let trash = EventBuilder::new(test.clone())
    .event(flowy_folder::event_map::FolderEvent::ListTrashItems)
    .async_send()
    .await
    .parse::<flowy_folder::entities::RepeatedTrashPB>()
    .items;
  assert!(trash.is_empty());
}

#[tokio::test]
async fn delete_all_trash_test() {
  let test = EventIntegrationTest::new_anon().await;
  let current_workspace = test.get_current_workspace().await;

  for i in 0..3 {
    let view = test
      .create_view(&current_workspace.id, format!("My {} view", i))
      .await;
    let payload = RepeatedViewIdPB {
      items: vec![view.id.clone()],
    };
    // delete the view. the view will be moved to trash
    EventBuilder::new(test.clone())
      .event(flowy_folder::event_map::FolderEvent::DeleteView)
      .payload(payload)
      .async_send()
      .await;
  }

  let trash = EventBuilder::new(test.clone())
    .event(flowy_folder::event_map::FolderEvent::ListTrashItems)
    .async_send()
    .await
    .parse::<flowy_folder::entities::RepeatedTrashPB>()
    .items;
  assert_eq!(trash.len(), 3);

  // Delete all the trash
  EventBuilder::new(test.clone())
    .event(flowy_folder::event_map::FolderEvent::PermanentlyDeleteAllTrashItem)
    .async_send()
    .await;

  // After delete the last view, the trash should be empty
  let trash = EventBuilder::new(test.clone())
    .event(flowy_folder::event_map::FolderEvent::ListTrashItems)
    .async_send()
    .await
    .parse::<flowy_folder::entities::RepeatedTrashPB>()
    .items;
  assert!(trash.is_empty());
}

#[tokio::test]
async fn multiple_hierarchy_view_test() {
  let test = EventIntegrationTest::new_anon().await;
  let current_workspace = test.get_current_workspace().await;
  for i in 1..4 {
    let parent = test
      .create_view(&current_workspace.id, format!("My {} view", i))
      .await;
    for j in 1..3 {
      let child = test
        .create_view(&parent.id, format!("My {}-{} view", i, j))
        .await;
      for k in 1..2 {
        let _sub_child = test
          .create_view(&child.id, format!("My {}-{}-{} view", i, j, k))
          .await;
      }
    }
  }

  let mut views = test.get_all_workspace_views().await;
  // There will be one default view when AppFlowy is initialized. So there will be 4 views in total
  assert_eq!(views.len(), 4);
  views.remove(0);

  // workspace
  //   - view1
  //     - view1-1
  //       - view1-1-1
  //     - view1-2
  //       - view1-2-1
  //   - view2
  //     - view2-1
  //       - view2-1-1
  //     - view2-2
  //       - view2-2-1
  //   - view3
  //     - view3-1
  //       - view3-1-1
  //     - view3-2
  //       - view3-2-1
  assert_eq!(views[0].name, "My 1 view");
  assert_eq!(views[1].name, "My 2 view");
  assert_eq!(views[2].name, "My 3 view");

  assert_eq!(views[0].child_views.len(), 2);
  // By default only the first level of child views will be loaded
  assert!(views[0].child_views[0].child_views.is_empty());

  for (i, view) in views.into_iter().enumerate() {
    for (j, child_view) in view.child_views.into_iter().enumerate() {
      let payload = ViewIdPB {
        value: child_view.id.clone(),
      };

      let child = EventBuilder::new(test.clone())
        .event(flowy_folder::event_map::FolderEvent::GetView)
        .payload(payload)
        .async_send()
        .await
        .parse::<flowy_folder::entities::ViewPB>();
      assert_eq!(child.name, format!("My {}-{} view", i + 1, j + 1));
      assert_eq!(child.child_views.len(), 1);
      // By default only the first level of child views will be loaded
      assert!(child.child_views[0].child_views.is_empty());

      for (k, _child_view) in child_view.child_views.into_iter().enumerate() {
        // Get the last level view
        let sub_child = test.get_view(&child.id).await;
        assert_eq!(child.name, format!("My {}-{}-{} view", i + 1, j + 1, k + 1));
        assert!(sub_child.child_views.is_empty());
      }
    }
  }
}

#[tokio::test]
async fn move_view_event_test() {
  let test = EventIntegrationTest::new_anon().await;
  let current_workspace = test.get_current_workspace().await;
  for i in 1..4 {
    let parent = test
      .create_view(&current_workspace.id, format!("My {} view", i))
      .await;
    for j in 1..3 {
      let _ = test
        .create_view(&parent.id, format!("My {}-{} view", i, j))
        .await;
    }
  }
  let views = test.get_all_workspace_views().await;
  // There will be one default view when AppFlowy is initialized. So there will be 4 views in total
  assert_eq!(views.len(), 4);
  assert_eq!(views[1].name, "My 1 view");
  assert_eq!(views[2].name, "My 2 view");
  assert_eq!(views[3].name, "My 3 view");

  let payload = MoveViewPayloadPB {
    view_id: views[1].id.clone(),
    from: 1,
    to: 2,
  };
  let _ = EventBuilder::new(test.clone())
    .event(flowy_folder::event_map::FolderEvent::MoveView)
    .payload(payload)
    .async_send()
    .await;

  let views = test.get_all_workspace_views().await;
  assert_eq!(views[1].name, "My 2 view");
  assert_eq!(views[2].name, "My 1 view");
  assert_eq!(views[3].name, "My 3 view");
}

#[tokio::test]
async fn move_view_event_after_delete_view_test() {
  let test = EventIntegrationTest::new_anon().await;
  let current_workspace = test.get_current_workspace().await;
  for i in 1..6 {
    let _ = test
      .create_view(&current_workspace.id, format!("My {} view", i))
      .await;
  }
  let views = test.get_all_workspace_views().await;
  assert_eq!(views[1].name, "My 1 view");
  assert_eq!(views[2].name, "My 2 view");
  assert_eq!(views[3].name, "My 3 view");
  assert_eq!(views[4].name, "My 4 view");
  assert_eq!(views[5].name, "My 5 view");
  test.delete_view(&views[3].id).await;

  // There will be one default view when AppFlowy is initialized. So there will be 4 views in total
  let views = test.get_all_workspace_views().await;
  assert_eq!(views[1].name, "My 1 view");
  assert_eq!(views[2].name, "My 2 view");
  assert_eq!(views[3].name, "My 4 view");
  assert_eq!(views[4].name, "My 5 view");

  let payload = MoveViewPayloadPB {
    view_id: views[1].id.clone(),
    from: 1,
    to: 3,
  };
  let _ = EventBuilder::new(test.clone())
    .event(flowy_folder::event_map::FolderEvent::MoveView)
    .payload(payload)
    .async_send()
    .await;

  let views = test.get_all_workspace_views().await;
  assert_eq!(views[1].name, "My 2 view");
  assert_eq!(views[2].name, "My 4 view");
  assert_eq!(views[3].name, "My 1 view");
  assert_eq!(views[4].name, "My 5 view");
}

#[tokio::test]
async fn move_view_event_after_delete_view_test2() {
  let test = EventIntegrationTest::new_anon().await;
  let current_workspace = test.get_current_workspace().await;
  let parent = test
    .create_view(&current_workspace.id, "My view".to_string())
    .await;

  for j in 1..6 {
    let _ = test
      .create_view(&parent.id, format!("My 1-{} view", j))
      .await;
  }

  let views = test.get_view(&parent.id).await.child_views;
  assert_eq!(views.len(), 5);
  assert_eq!(views[0].name, "My 1-1 view");
  assert_eq!(views[1].name, "My 1-2 view");
  assert_eq!(views[2].name, "My 1-3 view");
  assert_eq!(views[3].name, "My 1-4 view");
  assert_eq!(views[4].name, "My 1-5 view");
  test.delete_view(&views[2].id).await;

  let payload = MoveViewPayloadPB {
    view_id: views[0].id.clone(),
    from: 0,
    to: 2,
  };
  let _ = EventBuilder::new(test.clone())
    .event(flowy_folder::event_map::FolderEvent::MoveView)
    .payload(payload)
    .async_send()
    .await;

  let views = test.get_view(&parent.id).await.child_views;
  assert_eq!(views[0].name, "My 1-2 view");
  assert_eq!(views[1].name, "My 1-4 view");
  assert_eq!(views[2].name, "My 1-1 view");
  assert_eq!(views[3].name, "My 1-5 view");
}

#[tokio::test]
async fn create_parent_view_with_invalid_name() {
  for (name, code) in invalid_workspace_name_test_case() {
    let sdk = EventIntegrationTest::new().await;
    let request = CreateWorkspacePayloadPB {
      name,
      desc: "".to_owned(),
    };
    assert_eq!(
      EventBuilder::new(sdk)
        .event(flowy_folder::event_map::FolderEvent::CreateFolderWorkspace)
        .payload(request)
        .async_send()
        .await
        .error()
        .unwrap()
        .code,
      code
    )
  }
}

fn invalid_workspace_name_test_case() -> Vec<(String, ErrorCode)> {
  vec![
    ("".to_owned(), ErrorCode::WorkspaceNameInvalid),
    ("1234".repeat(100), ErrorCode::WorkspaceNameTooLong),
  ]
}

#[tokio::test]
async fn move_view_across_parent_test() {
  let test = EventIntegrationTest::new_anon().await;
  let current_workspace = test.get_current_workspace().await;
  let parent_1 = test
    .create_view(&current_workspace.id, "My view 1".to_string())
    .await;
  let parent_2 = test
    .create_view(&current_workspace.id, "My view 2".to_string())
    .await;

  for j in 1..6 {
    let _ = test
      .create_view(&parent_1.id, format!("My 1-{} view 1", j))
      .await;
  }

  let views = test.get_view(&parent_1.id).await.child_views;
  // Move `My 1-1 view 1` to `My view 2`
  let move_view_id = views[0].id.clone();
  let new_parent_id = parent_2.id.clone();
  let prev_id = None;
  move_folder_nested_view(test.clone(), move_view_id, new_parent_id, prev_id).await;
  let parent1_views = test.get_view(&parent_1.id).await.child_views;
  let parent2_views = test.get_view(&parent_2.id).await.child_views;
  assert_eq!(parent2_views.len(), 1);
  assert_eq!(parent2_views[0].name, "My 1-1 view 1");
  assert_eq!(parent1_views[0].name, "My 1-2 view 1");

  // Move My 1-2 view 1 from My view 1 to the current workspace and insert it after My view 1.
  let move_view_id = parent1_views[0].id.clone();
  let new_parent_id = current_workspace.id.clone();
  let prev_id = Some(parent_1.id.clone());
  move_folder_nested_view(test.clone(), move_view_id, new_parent_id, prev_id).await;
  let parent1_views = test.get_view(&parent_1.id).await.child_views;
  let workspace_views = test.get_all_workspace_views().await;
  let workspace_views_len = workspace_views.len();
  assert_eq!(parent1_views[0].name, "My 1-3 view 1");
  assert_eq!(workspace_views[workspace_views_len - 3].name, "My view 1");
  assert_eq!(
    workspace_views[workspace_views_len - 2].name,
    "My 1-2 view 1"
  );
  assert_eq!(workspace_views[workspace_views_len - 1].name, "My view 2");
}

async fn move_folder_nested_view(
  sdk: EventIntegrationTest,
  view_id: String,
  new_parent_id: String,
  prev_view_id: Option<String>,
) {
  let payload = MoveNestedViewPayloadPB {
    view_id,
    new_parent_id,
    prev_view_id,
    from_section: None,
    to_section: None,
  };
  EventBuilder::new(sdk)
    .event(flowy_folder::event_map::FolderEvent::MoveNestedView)
    .payload(payload)
    .async_send()
    .await;
}
