use collab_folder::core::ViewLayout;

use flowy_folder2::entities::*;
use flowy_folder2::event_map::FolderEvent::*;
use flowy_test::event_builder::EventBuilder;
use flowy_test::FlowyCoreTest;

pub enum FolderScript {
  // Workspace
  ReadAllWorkspaces,
  CreateWorkspace {
    name: String,
    desc: String,
  },
  AssertWorkspace(WorkspacePB),
  ReadWorkspace(Option<String>),

  // App
  CreateParentView {
    name: String,
    desc: String,
  },
  AssertParentView(ViewPB),
  ReloadParentView(String),
  UpdateParentView {
    name: Option<String>,
    desc: Option<String>,
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
  },
  DeleteView,
  DeleteViews(Vec<String>),

  // Trash
  RestoreAppFromTrash,
  RestoreViewFromTrash,
  ReadTrash,
  DeleteAllTrash,
}

pub struct FolderTest {
  pub sdk: FlowyCoreTest,
  pub all_workspace: Vec<WorkspacePB>,
  pub workspace: WorkspacePB,
  pub parent_view: ViewPB,
  pub child_view: ViewPB,
  pub trash: Vec<TrashPB>,
}

impl FolderTest {
  pub async fn new() -> Self {
    let sdk = FlowyCoreTest::new();
    let _ = sdk.init_user().await;
    let workspace = create_workspace(&sdk, "FolderWorkspace", "Folder test workspace").await;
    let parent_view = create_app(&sdk, &workspace.id, "Folder App", "Folder test app").await;
    let view = create_view(
      &sdk,
      &parent_view.id,
      "Folder View",
      "Folder test view",
      ViewLayout::Document,
    )
    .await;
    Self {
      sdk,
      all_workspace: vec![],
      workspace,
      parent_view,
      child_view: view,
      trash: vec![],
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
      FolderScript::ReadAllWorkspaces => {
        let all_workspace = read_workspace(sdk, None).await;
        self.all_workspace = all_workspace;
      },
      FolderScript::CreateWorkspace { name, desc } => {
        let workspace = create_workspace(sdk, &name, &desc).await;
        self.workspace = workspace;
      },
      FolderScript::AssertWorkspace(workspace) => {
        assert_eq!(self.workspace, workspace, "Workspace not equal");
      },
      FolderScript::ReadWorkspace(workspace_id) => {
        let workspace = read_workspace(sdk, workspace_id).await.pop().unwrap();
        self.workspace = workspace;
      },
      FolderScript::CreateParentView { name, desc } => {
        let app = create_app(sdk, &self.workspace.id, &name, &desc).await;
        self.parent_view = app;
      },
      FolderScript::AssertParentView(app) => {
        assert_eq!(self.parent_view, app, "App not equal");
      },
      FolderScript::ReloadParentView(parent_view_id) => {
        let parent_view = read_view(sdk, &parent_view_id).await;
        self.parent_view = parent_view;
      },
      FolderScript::UpdateParentView { name, desc } => {
        update_view(sdk, &self.parent_view.id, name, desc).await;
      },
      FolderScript::DeleteParentView => {
        delete_view(sdk, vec![self.parent_view.id.clone()]).await;
      },
      FolderScript::CreateView { name, desc, layout } => {
        let view = create_view(sdk, &self.parent_view.id, &name, &desc, layout).await;
        self.child_view = view;
      },
      FolderScript::AssertView(view) => {
        assert_eq!(self.child_view, view, "View not equal");
      },
      FolderScript::ReadView(view_id) => {
        let view = read_view(sdk, &view_id).await;
        self.child_view = view;
      },
      FolderScript::UpdateView { name, desc } => {
        update_view(sdk, &self.child_view.id, name, desc).await;
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
    }
  }
}
pub async fn create_workspace(sdk: &FlowyCoreTest, name: &str, desc: &str) -> WorkspacePB {
  let request = CreateWorkspacePayloadPB {
    name: name.to_owned(),
    desc: desc.to_owned(),
  };

  EventBuilder::new(sdk.clone())
    .event(CreateWorkspace)
    .payload(request)
    .async_send()
    .await
    .parse::<WorkspacePB>()
}

pub async fn read_workspace(sdk: &FlowyCoreTest, workspace_id: Option<String>) -> Vec<WorkspacePB> {
  let request = WorkspaceIdPB {
    value: workspace_id,
  };
  let repeated_workspace = EventBuilder::new(sdk.clone())
    .event(ReadAllWorkspaces)
    .payload(request.clone())
    .async_send()
    .await
    .parse::<RepeatedWorkspacePB>();

  let workspaces;
  if let Some(workspace_id) = &request.value {
    workspaces = repeated_workspace
      .items
      .into_iter()
      .filter(|workspace| &workspace.id == workspace_id)
      .collect::<Vec<WorkspacePB>>();
    debug_assert_eq!(workspaces.len(), 1);
  } else {
    workspaces = repeated_workspace.items;
  }

  workspaces
}

pub async fn create_app(sdk: &FlowyCoreTest, workspace_id: &str, name: &str, desc: &str) -> ViewPB {
  let create_view_request = CreateViewPayloadPB {
    parent_view_id: workspace_id.to_owned(),
    name: name.to_string(),
    desc: desc.to_string(),
    thumbnail: None,
    layout: ViewLayout::Document.into(),
    initial_data: vec![],
    meta: Default::default(),
    set_as_current: true,
  };

  EventBuilder::new(sdk.clone())
    .event(CreateView)
    .payload(create_view_request)
    .async_send()
    .await
    .parse::<ViewPB>()
}

pub async fn create_view(
  sdk: &FlowyCoreTest,
  app_id: &str,
  name: &str,
  desc: &str,
  layout: ViewLayout,
) -> ViewPB {
  let request = CreateViewPayloadPB {
    parent_view_id: app_id.to_string(),
    name: name.to_string(),
    desc: desc.to_string(),
    thumbnail: None,
    layout: layout.into(),
    initial_data: vec![],
    meta: Default::default(),
    set_as_current: true,
  };
  EventBuilder::new(sdk.clone())
    .event(CreateView)
    .payload(request)
    .async_send()
    .await
    .parse::<ViewPB>()
}

pub async fn read_view(sdk: &FlowyCoreTest, view_id: &str) -> ViewPB {
  let view_id = ViewIdPB::from(view_id);
  EventBuilder::new(sdk.clone())
    .event(ReadView)
    .payload(view_id)
    .async_send()
    .await
    .parse::<ViewPB>()
}

pub async fn update_view(
  sdk: &FlowyCoreTest,
  view_id: &str,
  name: Option<String>,
  desc: Option<String>,
) {
  let request = UpdateViewPayloadPB {
    view_id: view_id.to_string(),
    name,
    desc,
    thumbnail: None,
    layout: None,
  };
  EventBuilder::new(sdk.clone())
    .event(UpdateView)
    .payload(request)
    .async_send()
    .await;
}

pub async fn delete_view(sdk: &FlowyCoreTest, view_ids: Vec<String>) {
  let request = RepeatedViewIdPB { items: view_ids };
  EventBuilder::new(sdk.clone())
    .event(DeleteView)
    .payload(request)
    .async_send()
    .await;
}

pub async fn read_trash(sdk: &FlowyCoreTest) -> RepeatedTrashPB {
  EventBuilder::new(sdk.clone())
    .event(ReadTrash)
    .async_send()
    .await
    .parse::<RepeatedTrashPB>()
}

pub async fn restore_app_from_trash(sdk: &FlowyCoreTest, app_id: &str) {
  let id = TrashIdPB {
    id: app_id.to_owned(),
  };
  EventBuilder::new(sdk.clone())
    .event(PutbackTrash)
    .payload(id)
    .async_send()
    .await;
}

pub async fn restore_view_from_trash(sdk: &FlowyCoreTest, view_id: &str) {
  let id = TrashIdPB {
    id: view_id.to_owned(),
  };
  EventBuilder::new(sdk.clone())
    .event(PutbackTrash)
    .payload(id)
    .async_send()
    .await;
}

pub async fn delete_all_trash(sdk: &FlowyCoreTest) {
  EventBuilder::new(sdk.clone())
    .event(DeleteAllTrash)
    .async_send()
    .await;
}
