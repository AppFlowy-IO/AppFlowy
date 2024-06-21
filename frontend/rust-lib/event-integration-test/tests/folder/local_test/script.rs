use collab_folder::ViewLayout;

use event_integration_test::event_builder::EventBuilder;
use event_integration_test::EventIntegrationTest;
use flowy_folder::entities::icon::{UpdateViewIconPayloadPB, ViewIconPB};
use flowy_folder::entities::*;
use flowy_folder::event_map::FolderEvent::*;

pub enum FolderScript {
  #[allow(dead_code)]
  CreateWorkspace {
    name: String,
    desc: String,
  },
  #[allow(dead_code)]
  AssertWorkspace(WorkspacePB),
  #[allow(dead_code)]
  ReadWorkspace(String),
  CreateParentView {
    name: String,
    desc: String,
  },
  AssertParentView(ViewPB),
  ReloadParentView(String),
  UpdateParentView {
    name: Option<String>,
    desc: Option<String>,
    is_favorite: Option<bool>,
  },
  DeleteParentView,

  // View
  CreateView {
    name: String,
    desc: String,
    layout: ViewLayout,
  },
  AssertView(ViewPB),
  ReadView(String),
  UpdateView {
    name: Option<String>,
    desc: Option<String>,
    is_favorite: Option<bool>,
  },
  UpdateViewIcon {
    icon: Option<ViewIconPB>,
  },
  DeleteView,
  DeleteViews(Vec<String>),
  MoveView {
    view_id: String,
    new_parent_id: String,
    prev_view_id: Option<String>,
  },

  // Trash
  RestoreAppFromTrash,
  RestoreViewFromTrash,
  ReadTrash,
  DeleteAllTrash,
  ToggleFavorite,
  ReadFavorites,
}

pub struct FolderTest {
  pub sdk: EventIntegrationTest,
  pub workspace: WorkspacePB,
  pub parent_view: ViewPB,
  pub child_view: ViewPB,
  pub trash: Vec<TrashPB>,
  pub favorites: Vec<ViewPB>,
}

impl FolderTest {
  pub async fn new() -> Self {
    let sdk = EventIntegrationTest::new().await;
    let _ = sdk.init_anon_user().await;
    let workspace = sdk.folder_manager.get_current_workspace().await.unwrap();
    let parent_view = create_view(
      &sdk,
      &workspace.id,
      "first level view",
      "",
      ViewLayout::Document,
    )
    .await;
    let view = create_view(
      &sdk,
      &parent_view.id,
      "second level view",
      "",
      ViewLayout::Document,
    )
    .await;
    Self {
      sdk,
      workspace,
      parent_view,
      child_view: view,
      trash: vec![],
      favorites: vec![],
    }
  }

  pub async fn run_scripts(&mut self, scripts: Vec<FolderScript>) {
    for script in scripts {
      self.run_script(script).await;
    }
  }

  pub async fn run_script(&mut self, script: FolderScript) {
    let sdk = &self.sdk;
    match script {
      FolderScript::CreateWorkspace { name, desc } => {
        let workspace = create_workspace(sdk, &name, &desc).await;
        self.workspace = workspace;
      },
      FolderScript::AssertWorkspace(workspace) => {
        assert_eq!(self.workspace, workspace, "Workspace not equal");
      },
      FolderScript::ReadWorkspace(workspace_id) => {
        let workspace = read_workspace(sdk, workspace_id).await;
        self.workspace = workspace;
      },
      FolderScript::CreateParentView { name, desc } => {
        let app = create_view(sdk, &self.workspace.id, &name, &desc, ViewLayout::Document).await;
        self.parent_view = app;
      },
      FolderScript::AssertParentView(view) => {
        assert_eq!(self.parent_view.id, view.id, "view id not equal");
        assert_eq!(self.parent_view.name, view.name, "view name not equal");
        assert_eq!(
          self.parent_view.is_favorite, view.is_favorite,
          "view name not equal"
        );
      },
      FolderScript::ReloadParentView(parent_view_id) => {
        let parent_view = read_view(sdk, &parent_view_id).await;
        self.parent_view = parent_view;
      },
      FolderScript::UpdateParentView {
        name,
        desc,
        is_favorite,
      } => {
        update_view(sdk, &self.parent_view.id, name, desc, is_favorite).await;
      },
      FolderScript::DeleteParentView => {
        delete_view(sdk, vec![self.parent_view.id.clone()]).await;
      },
      FolderScript::CreateView { name, desc, layout } => {
        let view = create_view(sdk, &self.parent_view.id, &name, &desc, layout).await;
        self.child_view = view;
      },
      FolderScript::MoveView {
        view_id,
        new_parent_id,
        prev_view_id,
      } => {
        move_view(sdk, view_id, new_parent_id, prev_view_id).await;
      },
      FolderScript::AssertView(view) => {
        assert_eq!(self.child_view, view, "View not equal");
      },
      FolderScript::ReadView(view_id) => {
        let mut view = read_view(sdk, &view_id).await;
        // Ignore the last edited time
        view.last_edited = 0;
        self.child_view = view;
      },
      FolderScript::UpdateView {
        name,
        desc,
        is_favorite,
      } => {
        update_view(sdk, &self.child_view.id, name, desc, is_favorite).await;
      },
      FolderScript::UpdateViewIcon { icon } => {
        update_view_icon(sdk, &self.child_view.id, icon).await;
      },
      FolderScript::DeleteView => {
        delete_view(sdk, vec![self.child_view.id.clone()]).await;
      },
      FolderScript::DeleteViews(view_ids) => {
        delete_view(sdk, view_ids).await;
      },
      FolderScript::RestoreAppFromTrash => {
        restore_app_from_trash(sdk, &self.parent_view.id).await;
      },
      FolderScript::RestoreViewFromTrash => {
        restore_view_from_trash(sdk, &self.child_view.id).await;
      },
      FolderScript::ReadTrash => {
        let trash = read_trash(sdk).await;
        self.trash = trash.items;
      },
      FolderScript::DeleteAllTrash => {
        delete_all_trash(sdk).await;
        self.trash = vec![];
      },
      FolderScript::ToggleFavorite => {
        toggle_favorites(sdk, vec![self.child_view.id.clone()]).await;
      },
      FolderScript::ReadFavorites => {
        let favorites = read_favorites(sdk).await;
        self.favorites = favorites.items.iter().map(|x| x.item.clone()).collect();
      },
    }
  }
}
pub async fn create_workspace(sdk: &EventIntegrationTest, name: &str, desc: &str) -> WorkspacePB {
  let request = CreateWorkspacePayloadPB {
    name: name.to_owned(),
    desc: desc.to_owned(),
  };

  EventBuilder::new(sdk.clone())
    .event(CreateFolderWorkspace)
    .payload(request)
    .async_send()
    .await
    .parse::<WorkspacePB>()
}

pub async fn read_workspace(sdk: &EventIntegrationTest, workspace_id: String) -> WorkspacePB {
  let request = WorkspaceIdPB {
    value: workspace_id,
  };
  EventBuilder::new(sdk.clone())
    .event(ReadCurrentWorkspace)
    .payload(request.clone())
    .async_send()
    .await
    .parse::<WorkspacePB>()
}

pub async fn create_view(
  sdk: &EventIntegrationTest,
  parent_view_id: &str,
  name: &str,
  desc: &str,
  layout: ViewLayout,
) -> ViewPB {
  let request = CreateViewPayloadPB {
    parent_view_id: parent_view_id.to_string(),
    name: name.to_string(),
    desc: desc.to_string(),
    thumbnail: None,
    layout: layout.into(),
    initial_data: vec![],
    meta: Default::default(),
    set_as_current: true,
    index: None,
    section: None,
    view_id: None,
  };
  EventBuilder::new(sdk.clone())
    .event(CreateView)
    .payload(request)
    .async_send()
    .await
    .parse::<ViewPB>()
}

pub async fn read_view(sdk: &EventIntegrationTest, view_id: &str) -> ViewPB {
  let view_id = ViewIdPB::from(view_id);
  EventBuilder::new(sdk.clone())
    .event(GetView)
    .payload(view_id)
    .async_send()
    .await
    .parse::<ViewPB>()
}

pub async fn move_view(
  sdk: &EventIntegrationTest,
  view_id: String,
  parent_id: String,
  prev_view_id: Option<String>,
) {
  let payload = MoveNestedViewPayloadPB {
    view_id,
    new_parent_id: parent_id,
    prev_view_id,
    from_section: None,
    to_section: None,
  };
  let error = EventBuilder::new(sdk.clone())
    .event(MoveNestedView)
    .payload(payload)
    .async_send()
    .await
    .error();

  assert!(error.is_none());
}
pub async fn update_view(
  sdk: &EventIntegrationTest,
  view_id: &str,
  name: Option<String>,
  desc: Option<String>,
  is_favorite: Option<bool>,
) {
  println!("Toggling update view {:?}", is_favorite);
  let request = UpdateViewPayloadPB {
    view_id: view_id.to_string(),
    name,
    desc,
    is_favorite,
    ..Default::default()
  };
  EventBuilder::new(sdk.clone())
    .event(UpdateView)
    .payload(request)
    .async_send()
    .await;
}

pub async fn update_view_icon(sdk: &EventIntegrationTest, view_id: &str, icon: Option<ViewIconPB>) {
  let request = UpdateViewIconPayloadPB {
    view_id: view_id.to_string(),
    icon,
  };
  EventBuilder::new(sdk.clone())
    .event(UpdateViewIcon)
    .payload(request)
    .async_send()
    .await;
}

pub async fn delete_view(sdk: &EventIntegrationTest, view_ids: Vec<String>) {
  let request = RepeatedViewIdPB { items: view_ids };
  EventBuilder::new(sdk.clone())
    .event(DeleteView)
    .payload(request)
    .async_send()
    .await;
}

pub async fn read_trash(sdk: &EventIntegrationTest) -> RepeatedTrashPB {
  EventBuilder::new(sdk.clone())
    .event(ListTrashItems)
    .async_send()
    .await
    .parse::<RepeatedTrashPB>()
}

pub async fn restore_app_from_trash(sdk: &EventIntegrationTest, app_id: &str) {
  let id = TrashIdPB {
    id: app_id.to_owned(),
  };
  EventBuilder::new(sdk.clone())
    .event(RestoreTrashItem)
    .payload(id)
    .async_send()
    .await;
}

pub async fn restore_view_from_trash(sdk: &EventIntegrationTest, view_id: &str) {
  let id = TrashIdPB {
    id: view_id.to_owned(),
  };
  EventBuilder::new(sdk.clone())
    .event(RestoreTrashItem)
    .payload(id)
    .async_send()
    .await;
}

pub async fn delete_all_trash(sdk: &EventIntegrationTest) {
  EventBuilder::new(sdk.clone())
    .event(PermanentlyDeleteAllTrashItem)
    .async_send()
    .await;
}

pub async fn toggle_favorites(sdk: &EventIntegrationTest, view_id: Vec<String>) {
  let request = RepeatedViewIdPB { items: view_id };
  EventBuilder::new(sdk.clone())
    .event(ToggleFavorite)
    .payload(request)
    .async_send()
    .await;
}

pub async fn read_favorites(sdk: &EventIntegrationTest) -> RepeatedFavoriteViewPB {
  EventBuilder::new(sdk.clone())
    .event(ReadFavorites)
    .async_send()
    .await
    .parse::<RepeatedFavoriteViewPB>()
}
