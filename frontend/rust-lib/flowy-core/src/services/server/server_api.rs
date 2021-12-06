use crate::{
    entities::{
        app::{App, AppIdentifier, CreateAppParams, UpdateAppParams},
        trash::{RepeatedTrash, TrashIdentifiers},
        view::{CreateViewParams, UpdateViewParams, View, ViewIdentifier, ViewIdentifiers},
        workspace::{CreateWorkspaceParams, RepeatedWorkspace, UpdateWorkspaceParams, Workspace, WorkspaceIdentifier},
    },
    errors::WorkspaceError,
    notify::{send_dart_notification, WorkspaceNotification},
    services::server::WorkspaceServerAPI,
};
use backend_service::{configuration::ClientServerConfiguration, middleware::*, workspace_request::*};
use flowy_workspace_infra::errors::ErrorCode;
use lib_infra::future::ResultFuture;

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
                let error = WorkspaceError::new(ErrorCode::UserUnauthorized, "");
                send_dart_notification(&invalid_token, WorkspaceNotification::UserUnauthorized)
                    .error(error)
                    .send()
            }
        });
    }

    fn create_workspace(&self, token: &str, params: CreateWorkspaceParams) -> ResultFuture<Workspace, WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.workspace_url();
        ResultFuture::new(async move {
            let workspace = create_workspace_request(&token, params, &url).await?;
            Ok(workspace)
        })
    }

    fn read_workspace(
        &self,
        token: &str,
        params: WorkspaceIdentifier,
    ) -> ResultFuture<RepeatedWorkspace, WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.workspace_url();
        ResultFuture::new(async move {
            let repeated_workspace = read_workspaces_request(&token, params, &url).await?;
            Ok(repeated_workspace)
        })
    }

    fn update_workspace(&self, token: &str, params: UpdateWorkspaceParams) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.workspace_url();
        ResultFuture::new(async move {
            let _ = update_workspace_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn delete_workspace(&self, token: &str, params: WorkspaceIdentifier) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.workspace_url();
        ResultFuture::new(async move {
            let _ = delete_workspace_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn create_view(&self, token: &str, params: CreateViewParams) -> ResultFuture<View, WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.view_url();
        ResultFuture::new(async move {
            let view = create_view_request(&token, params, &url).await?;
            Ok(view)
        })
    }

    fn read_view(&self, token: &str, params: ViewIdentifier) -> ResultFuture<Option<View>, WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.view_url();
        ResultFuture::new(async move {
            let view = read_view_request(&token, params, &url).await?;
            Ok(view)
        })
    }

    fn delete_view(&self, token: &str, params: ViewIdentifiers) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.view_url();
        ResultFuture::new(async move {
            let _ = delete_view_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn update_view(&self, token: &str, params: UpdateViewParams) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.view_url();
        ResultFuture::new(async move {
            let _ = update_view_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn create_app(&self, token: &str, params: CreateAppParams) -> ResultFuture<App, WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.app_url();
        ResultFuture::new(async move {
            let app = create_app_request(&token, params, &url).await?;
            Ok(app)
        })
    }

    fn read_app(&self, token: &str, params: AppIdentifier) -> ResultFuture<Option<App>, WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.app_url();
        ResultFuture::new(async move {
            let app = read_app_request(&token, params, &url).await?;
            Ok(app)
        })
    }

    fn update_app(&self, token: &str, params: UpdateAppParams) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.app_url();
        ResultFuture::new(async move {
            let _ = update_app_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn delete_app(&self, token: &str, params: AppIdentifier) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.app_url();
        ResultFuture::new(async move {
            let _ = delete_app_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn create_trash(&self, token: &str, params: TrashIdentifiers) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.trash_url();
        ResultFuture::new(async move {
            let _ = create_trash_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn delete_trash(&self, token: &str, params: TrashIdentifiers) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.trash_url();
        ResultFuture::new(async move {
            let _ = delete_trash_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn read_trash(&self, token: &str) -> ResultFuture<RepeatedTrash, WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.trash_url();
        ResultFuture::new(async move {
            let repeated_trash = read_trash_request(&token, &url).await?;
            Ok(repeated_trash)
        })
    }
}
