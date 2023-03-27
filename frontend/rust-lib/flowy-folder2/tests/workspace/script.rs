use collab_folder::core::ViewLayout;
use flowy_error::ErrorCode;
use flowy_folder2::entities::*;
use flowy_folder2::event_map::FolderEvent::*;
use flowy_test::event_builder::Folder2EventBuilder;
use flowy_test::FlowySDKTest;
use std::sync::Arc;

pub enum FolderScript {
  // Workspace
  ReadAllWorkspaces,
  CreateWorkspace {
    name: String,
    desc: String,
  },
  // AssertWorkspaceRevisionJson(String),
  AssertWorkspace(WorkspacePB),
  ReadWorkspace(Option<String>),

  // App
  CreateApp {
    name: String,
    desc: String,
  },
  // AssertAppRevisionJson(String),
  AssertApp(AppPB),
  ReadApp(String),
  UpdateApp {
    name: Option<String>,
    desc: Option<String>,
  },
  DeleteApp,

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
  pub sdk: FlowySDKTest,
  pub all_workspace: Vec<WorkspacePB>,
  pub workspace: WorkspacePB,
  pub app: AppPB,
  pub view: ViewPB,
  pub trash: Vec<TrashPB>,
  // pub folder_editor:
}

impl FolderTest {
  pub async fn new() -> Self {
    let sdk = FlowySDKTest::default();
    let _ = sdk.init_user().await;
    let mut workspace = create_workspace(&sdk, "FolderWorkspace", "Folder test workspace").await;
    let mut app = create_app(&sdk, &workspace.id, "Folder App", "Folder test app").await;
    let view = create_view(
      &sdk,
      &app.id,
      "Folder View",
      "Folder test view",
      ViewLayout::Document,
    )
    .await;
    // app.belongings = RepeatedViewPB {
    //   items: vec![view.clone()],
    // };
    //
    // workspace.apps = RepeatedAppPB {
    //   items: vec![app.clone()],
    // };
    Self {
      sdk,
      all_workspace: vec![],
      workspace,
      app,
      view,
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
      FolderScript::CreateApp { name, desc } => {
        let app = create_app(sdk, &self.workspace.id, &name, &desc).await;
        self.app = app;
      },
      FolderScript::AssertApp(app) => {
        assert_eq!(self.app, app, "App not equal");
      },
      FolderScript::ReadApp(app_id) => {
        let app = read_app(sdk, &app_id).await;
        self.app = app;
      },
      FolderScript::UpdateApp { name, desc } => {
        update_app(sdk, &self.app.id, name, desc).await;
      },
      FolderScript::DeleteApp => {
        delete_app(sdk, &self.app.id).await;
      },

      FolderScript::CreateView { name, desc, layout } => {
        let view = create_view(sdk, &self.app.id, &name, &desc, layout).await;
        self.view = view;
      },
      FolderScript::AssertView(view) => {
        assert_eq!(self.view, view, "View not equal");
      },
      FolderScript::ReadView(view_id) => {
        let view = read_view(sdk, &view_id).await;
        self.view = view;
      },
      FolderScript::UpdateView { name, desc } => {
        update_view(sdk, &self.view.id, name, desc).await;
      },
      FolderScript::DeleteView => {
        delete_view(sdk, vec![self.view.id.clone()]).await;
      },
      FolderScript::DeleteViews(view_ids) => {
        delete_view(sdk, view_ids).await;
      },
      FolderScript::RestoreAppFromTrash => {
        restore_app_from_trash(sdk, &self.app.id).await;
      },
      FolderScript::RestoreViewFromTrash => {
        restore_view_from_trash(sdk, &self.view.id).await;
      },
      FolderScript::ReadTrash => {
        let mut trash = read_trash(sdk).await;
        self.trash = trash.items;
      },
      FolderScript::DeleteAllTrash => {
        delete_all_trash(sdk).await;
        self.trash = vec![];
      },
    }
  }
}

pub fn invalid_workspace_name_test_case() -> Vec<(String, ErrorCode)> {
  vec![
    ("".to_owned(), ErrorCode::WorkspaceNameInvalid),
    ("1234".repeat(100), ErrorCode::WorkspaceNameTooLong),
  ]
}

pub async fn create_workspace(sdk: &FlowySDKTest, name: &str, desc: &str) -> WorkspacePB {
  let request = CreateWorkspacePayloadPB {
    name: name.to_owned(),
    desc: desc.to_owned(),
  };

  Folder2EventBuilder::new(sdk.clone())
    .event(CreateWorkspace)
    .payload(request)
    .async_send()
    .await
    .parse::<WorkspacePB>()
}

pub async fn read_workspace(sdk: &FlowySDKTest, workspace_id: Option<String>) -> Vec<WorkspacePB> {
  let request = WorkspaceIdPB {
    value: workspace_id,
  };
  let mut repeated_workspace = Folder2EventBuilder::new(sdk.clone())
    .event(ReadWorkspaces)
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

pub async fn create_app(sdk: &FlowySDKTest, workspace_id: &str, name: &str, desc: &str) -> AppPB {
  let create_app_request = CreateAppPayloadPB {
    workspace_id: workspace_id.to_owned(),
    name: name.to_string(),
    desc: desc.to_string(),
    color_style: Default::default(),
  };

  Folder2EventBuilder::new(sdk.clone())
    .event(CreateApp)
    .payload(create_app_request)
    .async_send()
    .await
    .parse::<AppPB>()
}

pub async fn read_app(sdk: &FlowySDKTest, app_id: &str) -> AppPB {
  let request = AppIdPB {
    value: app_id.to_owned(),
  };

  Folder2EventBuilder::new(sdk.clone())
    .event(ReadApp)
    .payload(request)
    .async_send()
    .await
    .parse::<AppPB>()
}

pub async fn update_app(
  sdk: &FlowySDKTest,
  app_id: &str,
  name: Option<String>,
  desc: Option<String>,
) {
  let request = UpdateAppPayloadPB {
    app_id: app_id.to_string(),
    name,
    desc,
    color_style: None,
    is_trash: None,
  };

  Folder2EventBuilder::new(sdk.clone())
    .event(UpdateApp)
    .payload(request)
    .async_send()
    .await;
}

pub async fn delete_app(sdk: &FlowySDKTest, app_id: &str) {
  let request = AppIdPB {
    value: app_id.to_string(),
  };

  Folder2EventBuilder::new(sdk.clone())
    .event(DeleteApp)
    .payload(request)
    .async_send()
    .await;
}

pub async fn create_view(
  sdk: &FlowySDKTest,
  app_id: &str,
  name: &str,
  desc: &str,
  layout: ViewLayout,
) -> ViewPB {
  let request = CreateViewPayloadPB {
    belong_to_id: app_id.to_string(),
    name: name.to_string(),
    desc: desc.to_string(),
    thumbnail: None,
    layout: layout.into(),
    initial_data: vec![],
    ext: Default::default(),
  };
  Folder2EventBuilder::new(sdk.clone())
    .event(CreateView)
    .payload(request)
    .async_send()
    .await
    .parse::<ViewPB>()
}

pub async fn read_view(sdk: &FlowySDKTest, view_id: &str) -> ViewPB {
  let view_id: ViewIdPB = view_id.into();
  Folder2EventBuilder::new(sdk.clone())
    .event(ReadView)
    .payload(view_id)
    .async_send()
    .await
    .parse::<ViewPB>()
}

pub async fn update_view(
  sdk: &FlowySDKTest,
  view_id: &str,
  name: Option<String>,
  desc: Option<String>,
) {
  let request = UpdateViewPayloadPB {
    view_id: view_id.to_string(),
    name,
    desc,
    thumbnail: None,
  };
  Folder2EventBuilder::new(sdk.clone())
    .event(UpdateView)
    .payload(request)
    .async_send()
    .await;
}

pub async fn delete_view(sdk: &FlowySDKTest, view_ids: Vec<String>) {
  let request = RepeatedViewIdPB { items: view_ids };
  Folder2EventBuilder::new(sdk.clone())
    .event(DeleteView)
    .payload(request)
    .async_send()
    .await;
}

pub async fn read_trash(sdk: &FlowySDKTest) -> RepeatedTrashPB {
  Folder2EventBuilder::new(sdk.clone())
    .event(ReadTrash)
    .async_send()
    .await
    .parse::<RepeatedTrashPB>()
}

pub async fn restore_app_from_trash(sdk: &FlowySDKTest, app_id: &str) {
  let id = TrashIdPB {
    id: app_id.to_owned(),
  };
  Folder2EventBuilder::new(sdk.clone())
    .event(PutbackTrash)
    .payload(id)
    .async_send()
    .await;
}

pub async fn restore_view_from_trash(sdk: &FlowySDKTest, view_id: &str) {
  let id = TrashIdPB {
    id: view_id.to_owned(),
  };
  Folder2EventBuilder::new(sdk.clone())
    .event(PutbackTrash)
    .payload(id)
    .async_send()
    .await;
}

pub async fn delete_all_trash(sdk: &FlowySDKTest) {
  Folder2EventBuilder::new(sdk.clone())
    .event(DeleteAllTrash)
    .async_send()
    .await;
}
