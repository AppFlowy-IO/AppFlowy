use crate::entities::view::ViewDataFormatPB;
use crate::entities::{ViewLayoutTypePB, ViewPB};
use crate::services::folder_editor::FolderRevisionMergeable;
use crate::{
    dart_notification::{send_dart_notification, FolderNotification},
    entities::workspace::RepeatedWorkspacePB,
    errors::FlowyResult,
    event_map::{FolderCouldServiceV1, WorkspaceDatabase, WorkspaceUser},
    services::{
        folder_editor::FolderEditor, persistence::FolderPersistence, set_current_workspace, AppController,
        TrashController, ViewController, WorkspaceController,
    },
};
use bytes::Bytes;
use flowy_document::editor::initial_read_me;
use flowy_error::FlowyError;
use flowy_revision::{RevisionManager, RevisionPersistence, RevisionPersistenceConfiguration, RevisionWebSocket};
use folder_rev_model::user_default;
use lazy_static::lazy_static;
use lib_infra::future::FutureResult;

use crate::services::clear_current_workspace;
use crate::services::persistence::rev_sqlite::{
    SQLiteFolderRevisionPersistence, SQLiteFolderRevisionSnapshotPersistence,
};
use flowy_http_model::ws_data::ServerRevisionWSData;
use flowy_sync::client_folder::FolderPad;
use std::convert::TryFrom;
use std::{collections::HashMap, fmt::Formatter, sync::Arc};
use tokio::sync::RwLock as TokioRwLock;
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
        data_processors: ViewDataProcessorMap,
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
            data_processors,
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
        let result = ServerRevisionWSData::try_from(data);
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

    /// Called immediately after the application launched with the user sign in/sign up.
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
        self.persistence.initialize(user_id, &folder_id).await?;

        let pool = self.persistence.db_pool()?;
        let object_id = folder_id.as_ref();
        let disk_cache = SQLiteFolderRevisionPersistence::new(user_id, pool.clone());
        let configuration = RevisionPersistenceConfiguration::new(200, false);
        let rev_persistence = RevisionPersistence::new(user_id, object_id, disk_cache, configuration);
        let rev_compactor = FolderRevisionMergeable();

        let snapshot_object_id = format!("folder:{}", object_id);
        let snapshot_persistence = SQLiteFolderRevisionSnapshotPersistence::new(&snapshot_object_id, pool);
        let rev_manager = RevisionManager::new(
            user_id,
            folder_id.as_ref(),
            rev_persistence,
            rev_compactor,
            snapshot_persistence,
        );

        let folder_editor = FolderEditor::new(user_id, &folder_id, token, rev_manager, self.web_socket.clone()).await?;
        *self.folder_editor.write().await = Some(Arc::new(folder_editor));

        self.app_controller.initialize()?;
        self.view_controller.initialize()?;
        write_guard.insert(user_id.to_owned(), true);
        Ok(())
    }

    pub async fn initialize_with_new_user(
        &self,
        user_id: &str,
        token: &str,
        view_data_format: ViewDataFormatPB,
    ) -> FlowyResult<()> {
        DefaultFolderBuilder::build(
            token,
            user_id,
            self.persistence.clone(),
            self.view_controller.clone(),
            || (view_data_format.clone(), Bytes::from(initial_read_me())),
        )
        .await?;
        self.initialize(user_id, token).await
    }

    /// Called when the current user logout
    ///
    pub async fn clear(&self, user_id: &str) {
        self.view_controller.clear_latest_view();
        clear_current_workspace(user_id);
        *self.folder_editor.write().await = None;
    }
}

struct DefaultFolderBuilder();
impl DefaultFolderBuilder {
    async fn build<F: Fn() -> (ViewDataFormatPB, Bytes)>(
        token: &str,
        user_id: &str,
        persistence: Arc<FolderPersistence>,
        view_controller: Arc<ViewController>,
        create_view_fn: F,
    ) -> FlowyResult<()> {
        let workspace_rev = user_default::create_default_workspace();
        tracing::debug!("Create user:{} default workspace:{}", user_id, workspace_rev.id);
        set_current_workspace(user_id, &workspace_rev.id);
        for app in workspace_rev.apps.iter() {
            for (index, view) in app.belongings.iter().enumerate() {
                let (view_data_type, view_data) = create_view_fn();
                if index == 0 {
                    let _ = view_controller.set_latest_view(&view.id);
                    let layout_type = ViewLayoutTypePB::from(view.layout.clone());
                    view_controller
                        .create_view(&view.id, view_data_type, layout_type, view_data)
                        .await?;
                }
            }
        }
        let folder = FolderPad::new(vec![workspace_rev.clone()], vec![])?;
        let folder_id = FolderId::new(user_id);
        persistence.save_folder(user_id, &folder_id, folder).await?;
        let repeated_workspace = RepeatedWorkspacePB {
            items: vec![workspace_rev.into()],
        };
        send_dart_notification(token, FolderNotification::UserCreateWorkspace)
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

pub trait ViewDataProcessor {
    fn create_view(
        &self,
        user_id: &str,
        view_id: &str,
        layout: ViewLayoutTypePB,
        view_data: Bytes,
    ) -> FutureResult<(), FlowyError>;

    fn close_view(&self, view_id: &str) -> FutureResult<(), FlowyError>;

    fn get_view_data(&self, view: &ViewPB) -> FutureResult<Bytes, FlowyError>;

    fn create_default_view(
        &self,
        user_id: &str,
        view_id: &str,
        layout: ViewLayoutTypePB,
        data_format: ViewDataFormatPB,
    ) -> FutureResult<Bytes, FlowyError>;

    fn create_view_from_delta_data(
        &self,
        user_id: &str,
        view_id: &str,
        data: Vec<u8>,
        layout: ViewLayoutTypePB,
    ) -> FutureResult<Bytes, FlowyError>;

    fn data_types(&self) -> Vec<ViewDataFormatPB>;
}

pub type ViewDataProcessorMap = Arc<HashMap<ViewDataFormatPB, Arc<dyn ViewDataProcessor + Send + Sync>>>;
