use flowy_folder::entities::view::{RepeatedViewId, ViewId};
use flowy_folder::entities::workspace::WorkspaceId;
use flowy_folder::entities::{
    app::{App, RepeatedApp},
    trash::Trash,
    view::{RepeatedView, View, ViewDataType},
    workspace::Workspace,
};
use flowy_folder::entities::{
    app::{AppId, CreateAppPayload, UpdateAppPayload},
    trash::{RepeatedTrash, TrashId, TrashType},
    view::{CreateViewPayload, UpdateViewPayload},
    workspace::{CreateWorkspacePayload, RepeatedWorkspace},
};
use flowy_folder::event_map::FolderEvent::*;
use flowy_folder::{errors::ErrorCode, services::folder_editor::FolderEditor};

use flowy_revision::disk::RevisionState;
use flowy_revision::REVISION_WRITE_INTERVAL_IN_MILLIS;
use flowy_sync::entities::text_block::DocumentPB;
use flowy_test::{event_builder::*, FlowySDKTest};
use std::{sync::Arc, time::Duration};
use tokio::time::sleep;

pub enum FolderScript {
    // Workspace
    ReadAllWorkspaces,
    CreateWorkspace {
        name: String,
        desc: String,
    },
    // AssertWorkspaceRevisionJson(String),
    AssertWorkspace(Workspace),
    ReadWorkspace(Option<String>),

    // App
    CreateApp {
        name: String,
        desc: String,
    },
    // AssertAppRevisionJson(String),
    AssertApp(App),
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
        data_type: ViewDataType,
    },
    AssertView(View),
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

    // Sync
    AssertCurrentRevId(i64),
    AssertNextSyncRevId(Option<i64>),
    AssertRevisionState {
        rev_id: i64,
        state: RevisionState,
    },
}

pub struct FolderTest {
    pub sdk: FlowySDKTest,
    pub all_workspace: Vec<Workspace>,
    pub workspace: Workspace,
    pub app: App,
    pub view: View,
    pub trash: Vec<Trash>,
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
            ViewDataType::TextBlock,
        )
        .await;
        app.belongings = RepeatedView {
            items: vec![view.clone()],
        };

        workspace.apps = RepeatedApp {
            items: vec![app.clone()],
        };
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
        let folder_editor: Arc<FolderEditor> = sdk.folder_manager.folder_editor().await;
        let rev_manager = folder_editor.rev_manager();
        let cache = rev_manager.revision_cache().await;

        match script {
            FolderScript::ReadAllWorkspaces => {
                let all_workspace = read_workspace(sdk, None).await;
                self.all_workspace = all_workspace;
            }
            FolderScript::CreateWorkspace { name, desc } => {
                let workspace = create_workspace(sdk, &name, &desc).await;
                self.workspace = workspace;
            }
            // FolderScript::AssertWorkspaceRevisionJson(expected_json) => {
            //     let workspace = read_workspace(sdk, Some(self.workspace.id.clone()))
            //         .await
            //         .pop()
            //         .unwrap();
            //     let workspace_revision: WorkspaceRevision = workspace.into();
            //     let json = serde_json::to_string(&workspace_revision).unwrap();
            //     assert_eq!(json, expected_json);
            // }
            FolderScript::AssertWorkspace(workspace) => {
                assert_eq!(self.workspace, workspace);
            }
            FolderScript::ReadWorkspace(workspace_id) => {
                let workspace = read_workspace(sdk, workspace_id).await.pop().unwrap();
                self.workspace = workspace;
            }
            FolderScript::CreateApp { name, desc } => {
                let app = create_app(sdk, &self.workspace.id, &name, &desc).await;
                self.app = app;
            }
            // FolderScript::AssertAppRevisionJson(expected_json) => {
            //     let app_revision: AppRevision = self.app.clone().into();
            //     let json = serde_json::to_string(&app_revision).unwrap();
            //     assert_eq!(json, expected_json);
            // }
            FolderScript::AssertApp(app) => {
                assert_eq!(self.app, app);
            }
            FolderScript::ReadApp(app_id) => {
                let app = read_app(sdk, &app_id).await;
                self.app = app;
            }
            FolderScript::UpdateApp { name, desc } => {
                update_app(sdk, &self.app.id, name, desc).await;
            }
            FolderScript::DeleteApp => {
                delete_app(sdk, &self.app.id).await;
            }

            FolderScript::CreateView { name, desc, data_type } => {
                let view = create_view(sdk, &self.app.id, &name, &desc, data_type).await;
                self.view = view;
            }
            FolderScript::AssertView(view) => {
                assert_eq!(self.view, view);
            }
            FolderScript::ReadView(view_id) => {
                let view = read_view(sdk, &view_id).await;
                self.view = view;
            }
            FolderScript::UpdateView { name, desc } => {
                update_view(sdk, &self.view.id, name, desc).await;
            }
            FolderScript::DeleteView => {
                delete_view(sdk, vec![self.view.id.clone()]).await;
            }
            FolderScript::DeleteViews(view_ids) => {
                delete_view(sdk, view_ids).await;
            }
            FolderScript::RestoreAppFromTrash => {
                restore_app_from_trash(sdk, &self.app.id).await;
            }
            FolderScript::RestoreViewFromTrash => {
                restore_view_from_trash(sdk, &self.view.id).await;
            }
            FolderScript::ReadTrash => {
                let mut trash = read_trash(sdk).await;
                self.trash = trash.into_inner();
            }
            FolderScript::DeleteAllTrash => {
                delete_all_trash(sdk).await;
                self.trash = vec![];
            }
            FolderScript::AssertRevisionState { rev_id, state } => {
                let record = cache.get(rev_id).await.unwrap();
                assert_eq!(record.state, state);
                if let RevisionState::Ack = state {
                    // There is a defer action that writes the revisions to disk, so we wait here.
                    // Make sure everything is written.
                    sleep(Duration::from_millis(2 * REVISION_WRITE_INTERVAL_IN_MILLIS)).await;
                }
            }
            FolderScript::AssertCurrentRevId(rev_id) => {
                assert_eq!(rev_manager.rev_id(), rev_id, "Current rev_id is not match");
            }
            FolderScript::AssertNextSyncRevId(rev_id) => {
                let next_revision = rev_manager.next_sync_revision().await.unwrap();
                if rev_id.is_none() {
                    assert!(next_revision.is_none(), "Next revision should be None");
                    return;
                }
                let next_revision = next_revision
                    .unwrap_or_else(|| panic!("Expected Next revision is {}, but receive None", rev_id.unwrap()));
                let mut notify = rev_manager.ack_notify();
                let _ = notify.recv().await;
                assert_eq!(next_revision.rev_id, rev_id.unwrap());
            }
        }
    }
}

pub fn invalid_workspace_name_test_case() -> Vec<(String, ErrorCode)> {
    vec![
        ("".to_owned(), ErrorCode::WorkspaceNameInvalid),
        ("1234".repeat(100), ErrorCode::WorkspaceNameTooLong),
    ]
}

pub async fn create_workspace(sdk: &FlowySDKTest, name: &str, desc: &str) -> Workspace {
    let request = CreateWorkspacePayload {
        name: name.to_owned(),
        desc: desc.to_owned(),
    };

    let workspace = FolderEventBuilder::new(sdk.clone())
        .event(CreateWorkspace)
        .payload(request)
        .async_send()
        .await
        .parse::<Workspace>();
    workspace
}

pub async fn read_workspace(sdk: &FlowySDKTest, workspace_id: Option<String>) -> Vec<Workspace> {
    let request = WorkspaceId { value: workspace_id };
    let mut repeated_workspace = FolderEventBuilder::new(sdk.clone())
        .event(ReadWorkspaces)
        .payload(request.clone())
        .async_send()
        .await
        .parse::<RepeatedWorkspace>();

    let workspaces;
    if let Some(workspace_id) = &request.value {
        workspaces = repeated_workspace
            .into_inner()
            .into_iter()
            .filter(|workspace| &workspace.id == workspace_id)
            .collect::<Vec<Workspace>>();
        debug_assert_eq!(workspaces.len(), 1);
    } else {
        workspaces = repeated_workspace.items;
    }

    workspaces
}

pub async fn create_app(sdk: &FlowySDKTest, workspace_id: &str, name: &str, desc: &str) -> App {
    let create_app_request = CreateAppPayload {
        workspace_id: workspace_id.to_owned(),
        name: name.to_string(),
        desc: desc.to_string(),
        color_style: Default::default(),
    };

    let app = FolderEventBuilder::new(sdk.clone())
        .event(CreateApp)
        .payload(create_app_request)
        .async_send()
        .await
        .parse::<App>();
    app
}

pub async fn read_app(sdk: &FlowySDKTest, app_id: &str) -> App {
    let request = AppId {
        value: app_id.to_owned(),
    };

    let app = FolderEventBuilder::new(sdk.clone())
        .event(ReadApp)
        .payload(request)
        .async_send()
        .await
        .parse::<App>();

    app
}

pub async fn update_app(sdk: &FlowySDKTest, app_id: &str, name: Option<String>, desc: Option<String>) {
    let request = UpdateAppPayload {
        app_id: app_id.to_string(),
        name,
        desc,
        color_style: None,
        is_trash: None,
    };

    FolderEventBuilder::new(sdk.clone())
        .event(UpdateApp)
        .payload(request)
        .async_send()
        .await;
}

pub async fn delete_app(sdk: &FlowySDKTest, app_id: &str) {
    let request = AppId {
        value: app_id.to_string(),
    };

    FolderEventBuilder::new(sdk.clone())
        .event(DeleteApp)
        .payload(request)
        .async_send()
        .await;
}

pub async fn create_view(sdk: &FlowySDKTest, app_id: &str, name: &str, desc: &str, data_type: ViewDataType) -> View {
    let request = CreateViewPayload {
        belong_to_id: app_id.to_string(),
        name: name.to_string(),
        desc: desc.to_string(),
        thumbnail: None,
        data_type,
        plugin_type: 0,
        data: vec![],
    };
    let view = FolderEventBuilder::new(sdk.clone())
        .event(CreateView)
        .payload(request)
        .async_send()
        .await
        .parse::<View>();
    view
}

pub async fn read_view(sdk: &FlowySDKTest, view_id: &str) -> View {
    let view_id: ViewId = view_id.into();
    FolderEventBuilder::new(sdk.clone())
        .event(ReadView)
        .payload(view_id)
        .async_send()
        .await
        .parse::<View>()
}

pub async fn update_view(sdk: &FlowySDKTest, view_id: &str, name: Option<String>, desc: Option<String>) {
    let request = UpdateViewPayload {
        view_id: view_id.to_string(),
        name,
        desc,
        thumbnail: None,
    };
    FolderEventBuilder::new(sdk.clone())
        .event(UpdateView)
        .payload(request)
        .async_send()
        .await;
}

pub async fn delete_view(sdk: &FlowySDKTest, view_ids: Vec<String>) {
    let request = RepeatedViewId { items: view_ids };
    FolderEventBuilder::new(sdk.clone())
        .event(DeleteView)
        .payload(request)
        .async_send()
        .await;
}

#[allow(dead_code)]
pub async fn set_latest_view(sdk: &FlowySDKTest, view_id: &str) -> DocumentPB {
    let view_id: ViewId = view_id.into();
    FolderEventBuilder::new(sdk.clone())
        .event(SetLatestView)
        .payload(view_id)
        .async_send()
        .await
        .parse::<DocumentPB>()
}

pub async fn read_trash(sdk: &FlowySDKTest) -> RepeatedTrash {
    FolderEventBuilder::new(sdk.clone())
        .event(ReadTrash)
        .async_send()
        .await
        .parse::<RepeatedTrash>()
}

pub async fn restore_app_from_trash(sdk: &FlowySDKTest, app_id: &str) {
    let id = TrashId {
        id: app_id.to_owned(),
        ty: TrashType::TrashApp,
    };
    FolderEventBuilder::new(sdk.clone())
        .event(PutbackTrash)
        .payload(id)
        .async_send()
        .await;
}

pub async fn restore_view_from_trash(sdk: &FlowySDKTest, view_id: &str) {
    let id = TrashId {
        id: view_id.to_owned(),
        ty: TrashType::TrashView,
    };
    FolderEventBuilder::new(sdk.clone())
        .event(PutbackTrash)
        .payload(id)
        .async_send()
        .await;
}

pub async fn delete_all_trash(sdk: &FlowySDKTest) {
    FolderEventBuilder::new(sdk.clone())
        .event(DeleteAllTrash)
        .async_send()
        .await;
}
