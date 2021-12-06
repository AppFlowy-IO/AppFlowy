use crate::{
    entities::workspace::RepeatedWorkspace,
    errors::{WorkspaceError, WorkspaceResult},
    module::WorkspaceUser,
    notify::{send_dart_notification, WorkspaceNotification},
    services::{server::Server, AppController, TrashController, ViewController, WorkspaceController},
};
use chrono::Utc;
use flowy_document_infra::{entities::doc::DocDelta, user_default::initial_read_me};
use flowy_workspace_infra::user_default;
use lazy_static::lazy_static;
use lib_infra::entities::network_state::NetworkType;
use parking_lot::RwLock;
use std::{collections::HashMap, sync::Arc};

lazy_static! {
    static ref INIT_WORKSPACE: RwLock<HashMap<String, bool>> = RwLock::new(HashMap::new());
}

pub struct FlowyCore {
    pub user: Arc<dyn WorkspaceUser>,
    server: Server,
    pub workspace_controller: Arc<WorkspaceController>,
    pub(crate) app_controller: Arc<AppController>,
    pub(crate) view_controller: Arc<ViewController>,
    pub(crate) trash_controller: Arc<TrashController>,
}

impl FlowyCore {
    pub(crate) fn new(
        user: Arc<dyn WorkspaceUser>,
        server: Server,
        workspace_controller: Arc<WorkspaceController>,
        app_controller: Arc<AppController>,
        view_controller: Arc<ViewController>,
        trash_controller: Arc<TrashController>,
    ) -> Self {
        if let Ok(token) = user.token() {
            INIT_WORKSPACE.write().insert(token, false);
        }

        Self {
            user,
            server,
            workspace_controller,
            app_controller,
            view_controller,
            trash_controller,
        }
    }

    async fn init(&self, token: &str) -> Result<(), WorkspaceError> {
        if let Some(is_init) = INIT_WORKSPACE.read().get(token) {
            if *is_init {
                return Ok(());
            }
        }
        log::debug!("Start initializing flowy core");
        INIT_WORKSPACE.write().insert(token.to_owned(), true);
        let _ = self.server.init();
        let _ = self.workspace_controller.init()?;
        let _ = self.app_controller.init()?;
        let _ = self.view_controller.init()?;
        let _ = self.trash_controller.init()?;
        log::debug!("Finish initializing core");

        Ok(())
    }

    pub fn network_state_changed(&self, new_type: NetworkType) {
        match new_type {
            NetworkType::UnknownNetworkType => {},
            NetworkType::Wifi => {},
            NetworkType::Cell => {},
            NetworkType::Ethernet => {},
        }
    }

    pub async fn user_did_sign_in(&self, token: &str) -> WorkspaceResult<()> {
        // TODO: (nathan) do something here

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

    pub async fn user_did_sign_up(&self, _token: &str) -> WorkspaceResult<()> {
        log::debug!("Create user default workspace");
        let time = Utc::now();
        let mut workspace = user_default::create_default_workspace(time);
        let apps = workspace.take_apps().into_inner();
        let cloned_workspace = workspace.clone();

        let _ = self.workspace_controller.create_workspace(workspace).await?;
        for mut app in apps {
            let views = app.take_belongings().into_inner();
            let _ = self.app_controller.create_app(app).await?;
            for (index, view) in views.into_iter().enumerate() {
                if index == 0 {
                    let delta = initial_read_me();
                    let doc_delta = DocDelta {
                        doc_id: view.id.clone(),
                        data: delta.to_json(),
                    };
                    let _ = self.view_controller.apply_doc_delta(doc_delta).await?;

                    self.view_controller.set_latest_view(&view);
                }
                let _ = self.view_controller.create_view(view).await?;
            }
        }

        let token = self.user.token()?;
        let repeated_workspace = RepeatedWorkspace {
            items: vec![cloned_workspace],
        };

        send_dart_notification(&token, WorkspaceNotification::UserCreateWorkspace)
            .payload(repeated_workspace)
            .send();

        log::debug!("workspace initialize after sign up");
        let _ = self.init(&token).await?;
        Ok(())
    }
}
