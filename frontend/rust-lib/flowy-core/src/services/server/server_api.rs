use crate::{
    entities::{
        app::{App, AppIdentifier, CreateAppParams, UpdateAppParams},
        trash::{RepeatedTrash, TrashIdentifiers},
        view::{CreateViewParams, UpdateViewParams, View, ViewIdentifier, ViewIdentifiers},
        workspace::{CreateWorkspaceParams, RepeatedWorkspace, UpdateWorkspaceParams, Workspace, WorkspaceIdentifier},
    },
    errors::{ErrorCode, FlowyError},
    notify::{send_dart_notification, WorkspaceNotification},
    services::server::WorkspaceServerAPI,
};
use backend_service::{configuration::ClientServerConfiguration, middleware::*, workspace_request::*};
use lib_infra::future::FutureResult;

pub struct WorkspaceHttpServer {
    config: ClientServerConfiguration,
}

impl WorkspaceHttpServer {
    pub fn new(config: ClientServerConfiguration) -> WorkspaceHttpServer { Self { config } }
}

impl WorkspaceServerAPI for WorkspaceHttpServer {
    fn init(&self) {
        let mut rx = BACKEND_API_MIDDLEWARE.invalid_token_subscribe();
        tokio::spawn(async move {
            while let Ok(invalid_token) = rx.recv().await {
                let error = FlowyError::new(ErrorCode::UserUnauthorized, "");
                send_dart_notification(&invalid_token, WorkspaceNotification::UserUnauthorized)
                    .error(error)
                    .send()
            }
        });
    }

    fn create_workspace(&self, token: &str, params: CreateWorkspaceParams) -> FutureResult<Workspace, FlowyError> {
        let token = token.to_owned();
        let url = self.config.workspace_url();
        FutureResult::new(async move {
            let workspace = create_workspace_request(&token, params, &url).await?;
            Ok(workspace)
        })
    }

    fn read_workspace(&self, token: &str, params: WorkspaceIdentifier) -> FutureResult<RepeatedWorkspace, FlowyError> {
        let token = token.to_owned();
        let url = self.config.workspace_url();
        FutureResult::new(async move {
            let repeated_workspace = read_workspaces_request(&token, params, &url).await?;
            Ok(repeated_workspace)
        })
    }

    fn update_workspace(&self, token: &str, params: UpdateWorkspaceParams) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.workspace_url();
        FutureResult::new(async move {
            let _ = update_workspace_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn delete_workspace(&self, token: &str, params: WorkspaceIdentifier) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.workspace_url();
        FutureResult::new(async move {
            let _ = delete_workspace_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn create_view(&self, token: &str, params: CreateViewParams) -> FutureResult<View, FlowyError> {
        let token = token.to_owned();
        let url = self.config.view_url();
        FutureResult::new(async move {
            let view = create_view_request(&token, params, &url).await?;
            Ok(view)
        })
    }

    fn read_view(&self, token: &str, params: ViewIdentifier) -> FutureResult<Option<View>, FlowyError> {
        let token = token.to_owned();
        let url = self.config.view_url();
        FutureResult::new(async move {
            let view = read_view_request(&token, params, &url).await?;
            Ok(view)
        })
    }

    fn delete_view(&self, token: &str, params: ViewIdentifiers) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.view_url();
        FutureResult::new(async move {
            let _ = delete_view_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn update_view(&self, token: &str, params: UpdateViewParams) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.view_url();
        FutureResult::new(async move {
            let _ = update_view_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn create_app(&self, token: &str, params: CreateAppParams) -> FutureResult<App, FlowyError> {
        let token = token.to_owned();
        let url = self.config.app_url();
        FutureResult::new(async move {
            let app = create_app_request(&token, params, &url).await?;
            Ok(app)
        })
    }

    fn read_app(&self, token: &str, params: AppIdentifier) -> FutureResult<Option<App>, FlowyError> {
        let token = token.to_owned();
        let url = self.config.app_url();
        FutureResult::new(async move {
            let app = read_app_request(&token, params, &url).await?;
            Ok(app)
        })
    }

    fn update_app(&self, token: &str, params: UpdateAppParams) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.app_url();
        FutureResult::new(async move {
            let _ = update_app_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn delete_app(&self, token: &str, params: AppIdentifier) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.app_url();
        FutureResult::new(async move {
            let _ = delete_app_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn create_trash(&self, token: &str, params: TrashIdentifiers) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.trash_url();
        FutureResult::new(async move {
            let _ = create_trash_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn delete_trash(&self, token: &str, params: TrashIdentifiers) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.trash_url();
        FutureResult::new(async move {
            let _ = delete_trash_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn read_trash(&self, token: &str) -> FutureResult<RepeatedTrash, FlowyError> {
        let token = token.to_owned();
        let url = self.config.trash_url();
        FutureResult::new(async move {
            let repeated_trash = read_trash_request(&token, &url).await?;
            Ok(repeated_trash)
        })
    }
}
