use crate::helper::*;
use flowy_collaboration::entities::{document_info::BlockInfo, revision::RevisionState};
use flowy_folder::{errors::ErrorCode, services::folder_editor::ClientFolderEditor};
use flowy_folder_data_model::entities::{
    app::{App, RepeatedApp},
    trash::Trash,
    view::{RepeatedView, View, ViewDataType},
    workspace::Workspace,
};
use flowy_sync::REVISION_WRITE_INTERVAL_IN_MILLIS;
use flowy_test::FlowySDKTest;
use std::{sync::Arc, time::Duration};
use tokio::time::sleep;

pub enum FolderScript {
    // Workspace
    ReadAllWorkspaces,
    CreateWorkspace { name: String, desc: String },
    AssertWorkspaceJson(String),
    AssertWorkspace(Workspace),
    ReadWorkspace(Option<String>),

    // App
    CreateApp { name: String, desc: String },
    AssertAppJson(String),
    AssertApp(App),
    ReadApp(String),
    UpdateApp { name: Option<String>, desc: Option<String> },
    DeleteApp,

    // View
    CreateView { name: String, desc: String },
    AssertView(View),
    ReadView(String),
    UpdateView { name: Option<String>, desc: Option<String> },
    DeleteView,
    DeleteViews(Vec<String>),

    // Trash
    RestoreAppFromTrash,
    RestoreViewFromTrash,
    ReadTrash,
    DeleteAllTrash,

    // Document
    OpenDocument,

    // Sync
    AssertCurrentRevId(i64),
    AssertNextSyncRevId(Option<i64>),
    AssertRevisionState { rev_id: i64, state: RevisionState },
}

pub struct FolderTest {
    pub sdk: FlowySDKTest,
    pub all_workspace: Vec<Workspace>,
    pub workspace: Workspace,
    pub app: App,
    pub view: View,
    pub trash: Vec<Trash>,
    pub document_info: Option<BlockInfo>,
    // pub folder_editor:
}

impl FolderTest {
    pub async fn new() -> Self {
        let sdk = FlowySDKTest::default();
        let _ = sdk.init_user().await;
        let mut workspace = create_workspace(&sdk, "FolderWorkspace", "Folder test workspace").await;
        let mut app = create_app(&sdk, &workspace.id, "Folder App", "Folder test app").await;
        let view = create_view(&sdk, &app.id, "Folder View", "Folder test view", ViewDataType::Block).await;
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
            document_info: None,
        }
    }

    pub async fn run_scripts(&mut self, scripts: Vec<FolderScript>) {
        for script in scripts {
            self.run_script(script).await;
        }
    }

    pub async fn run_script(&mut self, script: FolderScript) {
        let sdk = &self.sdk;
        let folder_editor: Arc<ClientFolderEditor> = sdk.folder_manager.folder_editor().await;
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
            FolderScript::AssertWorkspaceJson(expected_json) => {
                let workspace = read_workspace(sdk, Some(self.workspace.id.clone()))
                    .await
                    .pop()
                    .unwrap();
                let json = serde_json::to_string(&workspace).unwrap();
                assert_eq!(json, expected_json);
            }
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
            FolderScript::AssertAppJson(expected_json) => {
                let json = serde_json::to_string(&self.app).unwrap();
                assert_eq!(json, expected_json);
            }
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

            FolderScript::CreateView { name, desc } => {
                let view = create_view(sdk, &self.app.id, &name, &desc, ViewDataType::Block).await;
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
                let trash = read_trash(sdk).await;
                self.trash = trash.into_inner();
            }
            FolderScript::DeleteAllTrash => {
                delete_all_trash(sdk).await;
                self.trash = vec![];
            }
            FolderScript::OpenDocument => {
                let document_info = open_document(sdk, &self.view.id).await;
                self.document_info = Some(document_info);
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
