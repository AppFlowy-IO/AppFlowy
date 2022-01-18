use bytes::Bytes;
use chrono::Utc;
use flowy_collaboration::client_document::default::{initial_delta, initial_read_me};
use flowy_core_data_model::{entities::view::CreateViewParams, user_default};
use flowy_document::context::DocumentContext;
use flowy_sync::RevisionWebSocket;
use lazy_static::lazy_static;

use futures_core::future::BoxFuture;

use parking_lot::RwLock;
use std::{collections::HashMap, sync::Arc};

use crate::{
    dart_notification::{send_dart_notification, WorkspaceNotification},
    entities::workspace::RepeatedWorkspace,
    errors::FlowyResult,
    module::{FolderCouldServiceV1, WorkspaceUser},
    services::{persistence::FolderPersistence, AppController, TrashController, ViewController, WorkspaceController},
};

lazy_static! {
    static ref INIT_WORKSPACE: RwLock<HashMap<String, bool>> = RwLock::new(HashMap::new());
}

pub struct FolderManager {
    pub user: Arc<dyn WorkspaceUser>,
    pub(crate) cloud_service: Arc<dyn FolderCouldServiceV1>,
    pub(crate) persistence: Arc<FolderPersistence>,
    pub workspace_controller: Arc<WorkspaceController>,
    pub(crate) app_controller: Arc<AppController>,
    pub(crate) view_controller: Arc<ViewController>,
    pub(crate) trash_controller: Arc<TrashController>,
    ws_sender: Arc<dyn RevisionWebSocket>,
}

impl FolderManager {
    pub(crate) fn new(
        user: Arc<dyn WorkspaceUser>,
        cloud_service: Arc<dyn FolderCouldServiceV1>,
        persistence: Arc<FolderPersistence>,
        flowy_document: Arc<DocumentContext>,
        ws_sender: Arc<dyn RevisionWebSocket>,
    ) -> Self {
        if let Ok(token) = user.token() {
            INIT_WORKSPACE.write().insert(token, false);
        }

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
            flowy_document,
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
            ws_sender,
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

    pub async fn did_receive_ws_data(&self, _data: Bytes) {}

    pub async fn initialize(&self, token: &str) -> FlowyResult<()> {
        self.initialize_with_fn(token, || Box::pin(async { Ok(()) })).await?;
        Ok(())
    }

    pub async fn clear(&self) { self.persistence.user_did_logout() }

    pub async fn initialize_with_new_user(&self, token: &str) -> FlowyResult<()> {
        self.initialize_with_fn(token, || Box::pin(self.initial_default_workspace()))
            .await
    }

    async fn initialize_with_fn<'a, F>(&'a self, token: &str, f: F) -> FlowyResult<()>
    where
        F: FnOnce() -> BoxFuture<'a, FlowyResult<()>>,
    {
        if let Some(is_init) = INIT_WORKSPACE.read().get(token) {
            if *is_init {
                return Ok(());
            }
        }
        INIT_WORKSPACE.write().insert(token.to_owned(), true);

        self.persistence.initialize().await?;
        f().await?;
        let _ = self.app_controller.initialize()?;
        let _ = self.view_controller.initialize()?;
        Ok(())
    }

    async fn initial_default_workspace(&self) -> FlowyResult<()> {
        log::debug!("Create user default workspace");
        let time = Utc::now();
        let workspace = user_default::create_default_workspace(time);
        let apps = workspace.apps.clone().into_inner();
        let cloned_workspace = workspace.clone();

        let _ = self.workspace_controller.create_workspace_on_local(workspace).await?;
        for app in apps {
            let app_id = app.id.clone();
            let views = app.belongings.clone().into_inner();
            let _ = self.app_controller.create_app_on_local(app).await?;
            for (index, view) in views.into_iter().enumerate() {
                let view_data = if index == 0 {
                    initial_read_me().to_json()
                } else {
                    initial_delta().to_json()
                };
                self.view_controller.set_latest_view(&view);
                let params = CreateViewParams {
                    belong_to_id: app_id.clone(),
                    name: view.name,
                    desc: view.desc,
                    thumbnail: "".to_string(),
                    view_type: view.view_type,
                    view_data,
                    view_id: view.id.clone(),
                };
                let _ = self.view_controller.create_view_from_params(params).await?;
            }
        }

        let token = self.user.token()?;
        let repeated_workspace = RepeatedWorkspace {
            items: vec![cloned_workspace],
        };

        send_dart_notification(&token, WorkspaceNotification::UserCreateWorkspace)
            .payload(repeated_workspace)
            .send();
        Ok(())
    }
}
