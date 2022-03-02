use bytes::Bytes;
use chrono::Utc;
use flowy_collaboration::client_document::default::{initial_delta, initial_read_me};
use flowy_folder_data_model::user_default;
use flowy_sync::RevisionWebSocket;
use lazy_static::lazy_static;

use flowy_collaboration::{client_folder::FolderPad, entities::ws_data::ServerRevisionWSData};
use flowy_document::BlockManager;

use flowy_collaboration::entities::revision::{RepeatedRevision, Revision};
use std::{collections::HashMap, convert::TryInto, fmt::Formatter, sync::Arc};
use tokio::sync::RwLock as TokioRwLock;

use crate::{
    dart_notification::{send_dart_notification, FolderNotification},
    entities::workspace::RepeatedWorkspace,
    errors::FlowyResult,
    event_map::{FolderCouldServiceV1, WorkspaceDatabase, WorkspaceUser},
    services::{
        folder_editor::ClientFolderEditor, persistence::FolderPersistence, set_current_workspace, AppController,
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
    folder_editor: Arc<TokioRwLock<Option<Arc<ClientFolderEditor>>>>,
}

impl FolderManager {
    pub async fn new(
        user: Arc<dyn WorkspaceUser>,
        cloud_service: Arc<dyn FolderCouldServiceV1>,
        database: Arc<dyn WorkspaceDatabase>,
        document_manager: Arc<BlockManager>,
        web_socket: Arc<dyn RevisionWebSocket>,
    ) -> Self {
        if let Ok(user_id) = user.user_id() {
            // Reset the flag if the folder manager gets initialized, otherwise,
            // the folder_editor will not be initialized after flutter hot reload.
            INIT_FOLDER_FLAG.write().await.insert(user_id.to_owned(), false);
        }

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

    #[tracing::instrument(level = "trace", skip(self), err)]
    pub async fn initialize(&self, user_id: &str, token: &str) -> FlowyResult<()> {
        let mut write_guard = INIT_FOLDER_FLAG.write().await;
        if let Some(is_init) = write_guard.get(user_id) {
            if *is_init {
                return Ok(());
            }
        }
        tracing::debug!("Initialize folder editor");
        let folder_id = FolderId::new(user_id);
        let _ = self.persistence.initialize(user_id, &folder_id).await?;

        let pool = self.persistence.db_pool()?;
        let folder_editor = ClientFolderEditor::new(user_id, &folder_id, token, pool, self.web_socket.clone()).await?;
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
                    initial_read_me().to_delta_json()
                } else {
                    initial_delta().to_delta_json()
                };
                view_controller.set_latest_view(view);
                let delta_data = Bytes::from(view_data);
                let repeated_revision: RepeatedRevision =
                    Revision::initial_revision(user_id, &view.id, delta_data).into();
                let _ = view_controller.create_view(&view.id, repeated_revision).await?;
            }
        }
        let folder = FolderPad::new(vec![workspace.clone()], vec![])?;
        let folder_id = FolderId::new(user_id);
        let _ = persistence.save_folder(user_id, &folder_id, folder).await?;
        let repeated_workspace = RepeatedWorkspace { items: vec![workspace] };
        send_dart_notification(token, FolderNotification::UserCreateWorkspace)
            .payload(repeated_workspace)
            .send();
        Ok(())
    }
}

#[cfg(feature = "flowy_unit_test")]
impl FolderManager {
    pub async fn folder_editor(&self) -> Arc<ClientFolderEditor> {
        self.folder_editor.read().await.clone().unwrap()
    }
}
