use bytes::Bytes;
use chrono::Utc;
use flowy_collaboration::client_document::default::{initial_delta, initial_read_me};
use flowy_core_data_model::{entities::view::CreateViewParams, user_default};
use flowy_document::context::DocumentContext;
use flowy_sync::RevisionWebSocket;
use lazy_static::lazy_static;
use parking_lot::RwLock;
use std::{collections::HashMap, sync::Arc};

use crate::{
    dart_notification::{send_dart_notification, WorkspaceNotification},
    entities::workspace::RepeatedWorkspace,
    errors::{FlowyError, FlowyResult},
    module::{WorkspaceCloudService, WorkspaceUser},
    services::{
        persistence::FlowyCorePersistence,
        AppController,
        TrashController,
        ViewController,
        WorkspaceController,
    },
};

lazy_static! {
    static ref INIT_WORKSPACE: RwLock<HashMap<String, bool>> = RwLock::new(HashMap::new());
}

pub struct FolderManager {
    pub user: Arc<dyn WorkspaceUser>,
    pub(crate) cloud_service: Arc<dyn WorkspaceCloudService>,
    pub(crate) persistence: Arc<FlowyCorePersistence>,
    pub workspace_controller: Arc<WorkspaceController>,
    pub(crate) app_controller: Arc<AppController>,
    pub(crate) view_controller: Arc<ViewController>,
    pub(crate) trash_controller: Arc<TrashController>,
    ws_sender: Arc<dyn RevisionWebSocket>,
}

impl FolderManager {
    pub(crate) fn new(
        user: Arc<dyn WorkspaceUser>,
        cloud_service: Arc<dyn WorkspaceCloudService>,
        persistence: Arc<FlowyCorePersistence>,
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

    pub async fn user_did_sign_in(&self, token: &str) -> FlowyResult<()> {
        log::debug!("workspace initialize after sign in");
        let _ = self.init(token).await?;
        Ok(())
    }

    pub async fn user_did_logout(&self) {
        // TODO: (nathan) do something here
    }

    pub async fn user_session_expired(&self) {
        // TODO: (nathan) do something here
    }

    pub async fn user_did_sign_up(&self, _token: &str) -> FlowyResult<()> {
        log::debug!("Create user default workspace");
        let time = Utc::now();
        let mut workspace = user_default::create_default_workspace(time);
        let apps = workspace.take_apps().into_inner();
        let cloned_workspace = workspace.clone();

        let _ = self.workspace_controller.create_workspace_on_local(workspace).await?;
        for mut app in apps {
            let app_id = app.id.clone();
            let views = app.take_belongings().into_inner();
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

        tracing::debug!("Create default workspace after sign up");
        let _ = self.init(&token).await?;
        Ok(())
    }

    async fn init(&self, token: &str) -> Result<(), FlowyError> {
        if let Some(is_init) = INIT_WORKSPACE.read().get(token) {
            if *is_init {
                return Ok(());
            }
        }
        INIT_WORKSPACE.write().insert(token.to_owned(), true);
        let _ = self.workspace_controller.init()?;
        let _ = self.app_controller.init()?;
        let _ = self.view_controller.init()?;
        let _ = self.trash_controller.init()?;

        Ok(())
    }
}
