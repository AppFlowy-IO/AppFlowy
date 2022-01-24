use bytes::Bytes;
use chrono::Utc;
use flowy_collaboration::client_document::default::{initial_delta, initial_read_me};
use flowy_core_data_model::user_default;
use flowy_sync::RevisionWebSocket;
use lazy_static::lazy_static;

use flowy_collaboration::{entities::ws_data::ServerRevisionWSData, folder::FolderPad};
use flowy_document::FlowyDocumentManager;

use std::{collections::HashMap, convert::TryInto, fmt::Formatter, sync::Arc};
use tokio::sync::RwLock as TokioRwLock;

use crate::{
    dart_notification::{send_dart_notification, WorkspaceNotification},
    entities::workspace::RepeatedWorkspace,
    errors::FlowyResult,
    module::{FolderCouldServiceV1, WorkspaceDatabase, WorkspaceUser},
    services::{
        folder_editor::FolderEditor, persistence::FolderPersistence, set_current_workspace, AppController,
        TrashController, ViewController, WorkspaceController,
    },
};

lazy_static! {
    static ref INIT_FOLDER_FLAG: TokioRwLock<HashMap<String, bool>> = TokioRwLock::new(HashMap::new());
}

const FOLDER_ID: &str = "folder";
const FOLDER_ID_SPLIT: &str = ":";
#[derive(Clone)]
pub struct FolderId(String);
impl FolderId {
    pub fn new(user_id: &str) -> Self {
        Self(format!("{}{}{}", user_id, FOLDER_ID_SPLIT, FOLDER_ID))
    }
}

impl std::fmt::Display for FolderId {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_str(FOLDER_ID)
    }
}

impl std::fmt::Debug for FolderId {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_str(FOLDER_ID)
    }
}

impl AsRef<str> for FolderId {
    fn as_ref(&self) -> &str {
        &self.0
    }
}

pub struct FolderManager {
    pub user: Arc<dyn WorkspaceUser>,
    pub(crate) cloud_service: Arc<dyn FolderCouldServiceV1>,
    pub(crate) persistence: Arc<FolderPersistence>,
    pub(crate) workspace_controller: Arc<WorkspaceController>,
    pub(crate) app_controller: Arc<AppController>,
    pub(crate) view_controller: Arc<ViewController>,
    pub(crate) trash_controller: Arc<TrashController>,
    web_socket: Arc<dyn RevisionWebSocket>,
    folder_editor: Arc<TokioRwLock<Option<Arc<FolderEditor>>>>,
}

impl FolderManager {
    pub async fn new(
        user: Arc<dyn WorkspaceUser>,
        cloud_service: Arc<dyn FolderCouldServiceV1>,
        database: Arc<dyn WorkspaceDatabase>,
        document_manager: Arc<FlowyDocumentManager>,
        web_socket: Arc<dyn RevisionWebSocket>,
    ) -> Self {
        let folder_editor = Arc::new(TokioRwLock::new(None));
        let persistence = Arc::new(FolderPersistence::new(database.clone(), folder_editor.clone()));

        let trash_controller = Arc::new(TrashController::new(
            persistence.clone(),
            cloud_service.clone(),
            user.clone(),
        ));

        let view_controller = Arc::new(ViewController::new(
            user.clone(),
            persistence.clone(),
            cloud_service.clone(),
            trash_controller.clone(),
            document_manager,
        ));

        let app_controller = Arc::new(AppController::new(
            user.clone(),
            persistence.clone(),
            trash_controller.clone(),
            cloud_service.clone(),
        ));

        let workspace_controller = Arc::new(WorkspaceController::new(
            user.clone(),
            persistence.clone(),
            trash_controller.clone(),
            cloud_service.clone(),
        ));

        Self {
            user,
            cloud_service,
            persistence,
            workspace_controller,
            app_controller,
            view_controller,
            trash_controller,
            web_socket,
            folder_editor,
        }
    }

    // pub fn network_state_changed(&self, new_type: NetworkType) {
    //     match new_type {
    //         NetworkType::UnknownNetworkType => {},
    //         NetworkType::Wifi => {},
    //         NetworkType::Cell => {},
    //         NetworkType::Ethernet => {},
    //     }
    // }

    pub async fn did_receive_ws_data(&self, data: Bytes) {
        let result: Result<ServerRevisionWSData, protobuf::ProtobufError> = data.try_into();
        match result {
            Ok(data) => match self.folder_editor.read().await.clone() {
                None => {}
                Some(editor) => match editor.receive_ws_data(data).await {
                    Ok(_) => {}
                    Err(e) => tracing::error!("Folder receive data error: {:?}", e),
                },
            },
            Err(e) => {
                tracing::error!("Folder ws data parser failed: {:?}", e);
            }
        }
    }

    pub async fn initialize(&self, user_id: &str, token: &str) -> FlowyResult<()> {
        let mut write_guard = INIT_FOLDER_FLAG.write().await;
        if let Some(is_init) = write_guard.get(user_id) {
            if *is_init {
                return Ok(());
            }
        }
        let folder_id = FolderId::new(user_id);
        let _ = self.persistence.initialize(user_id, &folder_id).await?;

        let pool = self.persistence.db_pool()?;
        let folder_editor = FolderEditor::new(user_id, &folder_id, token, pool, self.web_socket.clone()).await?;
        *self.folder_editor.write().await = Some(Arc::new(folder_editor));

        let _ = self.app_controller.initialize()?;
        let _ = self.view_controller.initialize()?;
        write_guard.insert(user_id.to_owned(), true);
        Ok(())
    }

    pub async fn initialize_with_new_user(&self, user_id: &str, token: &str) -> FlowyResult<()> {
        DefaultFolderBuilder::build(token, user_id, self.persistence.clone(), self.view_controller.clone()).await?;
        self.initialize(user_id, token).await
    }

    pub async fn clear(&self) {
        *self.folder_editor.write().await = None;
    }
}

struct DefaultFolderBuilder();
impl DefaultFolderBuilder {
    async fn build(
        token: &str,
        user_id: &str,
        persistence: Arc<FolderPersistence>,
        view_controller: Arc<ViewController>,
    ) -> FlowyResult<()> {
        log::debug!("Create user default workspace");
        let time = Utc::now();
        let workspace = user_default::create_default_workspace(time);
        set_current_workspace(&workspace.id);
        for app in workspace.apps.iter() {
            for (index, view) in app.belongings.iter().enumerate() {
                let view_data = if index == 0 {
                    initial_read_me().to_json()
                } else {
                    initial_delta().to_json()
                };
                view_controller.set_latest_view(view);
                let _ = view_controller
                    .create_view_document_content(&view.id, view_data)
                    .await?;
            }
        }
        let folder = FolderPad::new(vec![workspace.clone()], vec![])?;
        let folder_id = FolderId::new(user_id);
        let _ = persistence.save_folder(user_id, &folder_id, folder).await?;
        let repeated_workspace = RepeatedWorkspace { items: vec![workspace] };
        send_dart_notification(token, WorkspaceNotification::UserCreateWorkspace)
            .payload(repeated_workspace)
            .send();
        Ok(())
    }
}

#[cfg(feature = "flowy_unit_test")]
impl FolderManager {
    pub async fn folder_editor(&self) -> Arc<FolderEditor> {
        self.folder_editor.read().await.clone().unwrap()
    }
}
