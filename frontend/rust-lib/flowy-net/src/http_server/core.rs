use backend_service::{
    configuration::{ClientServerConfiguration, HEADER_TOKEN},
    errors::ServerError,
    request::{HttpRequestBuilder, ResponseMiddleware},
    response::FlowyResponse,
};
use flowy_error::FlowyError;
use flowy_folder_data_model::entities::{
    app::{App, AppId, CreateAppParams, UpdateAppParams},
    trash::{RepeatedTrash, RepeatedTrashId},
    view::{CreateViewParams, RepeatedViewId, UpdateViewParams, View, ViewId},
    workspace::{CreateWorkspaceParams, RepeatedWorkspace, UpdateWorkspaceParams, Workspace, WorkspaceId},
};

use flowy_folder::event_map::FolderCouldServiceV1;
use lazy_static::lazy_static;
use lib_infra::future::FutureResult;
use std::sync::Arc;
use tokio::sync::broadcast;

pub struct FolderHttpCloudService {
    config: ClientServerConfiguration,
}

impl FolderHttpCloudService {
    pub fn new(config: ClientServerConfiguration) -> FolderHttpCloudService {
        Self { config }
    }
}

impl FolderCouldServiceV1 for FolderHttpCloudService {
    fn init(&self) {}

    fn create_workspace(&self, token: &str, params: CreateWorkspaceParams) -> FutureResult<Workspace, FlowyError> {
        let token = token.to_owned();
        let url = self.config.workspace_url();
        FutureResult::new(async move {
            let workspace = create_workspace_request(&token, params, &url).await?;
            Ok(workspace)
        })
    }

    fn read_workspace(&self, token: &str, params: WorkspaceId) -> FutureResult<RepeatedWorkspace, FlowyError> {
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

    fn delete_workspace(&self, token: &str, params: WorkspaceId) -> FutureResult<(), FlowyError> {
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

    fn read_view(&self, token: &str, params: ViewId) -> FutureResult<Option<View>, FlowyError> {
        let token = token.to_owned();
        let url = self.config.view_url();
        FutureResult::new(async move {
            let view = read_view_request(&token, params, &url).await?;
            Ok(view)
        })
    }

    fn delete_view(&self, token: &str, params: RepeatedViewId) -> FutureResult<(), FlowyError> {
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

    fn read_app(&self, token: &str, params: AppId) -> FutureResult<Option<App>, FlowyError> {
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

    fn delete_app(&self, token: &str, params: AppId) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.app_url();
        FutureResult::new(async move {
            let _ = delete_app_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn create_trash(&self, token: &str, params: RepeatedTrashId) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.trash_url();
        FutureResult::new(async move {
            let _ = create_trash_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn delete_trash(&self, token: &str, params: RepeatedTrashId) -> FutureResult<(), FlowyError> {
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

fn request_builder() -> HttpRequestBuilder {
    HttpRequestBuilder::new().middleware(MIDDLEWARE.clone())
}

pub async fn create_workspace_request(
    token: &str,
    params: CreateWorkspaceParams,
    url: &str,
) -> Result<Workspace, ServerError> {
    let workspace = request_builder()
        .post(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .response()
        .await?;
    Ok(workspace)
}

pub async fn read_workspaces_request(
    token: &str,
    params: WorkspaceId,
    url: &str,
) -> Result<RepeatedWorkspace, ServerError> {
    let repeated_workspace = request_builder()
        .get(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .response::<RepeatedWorkspace>()
        .await?;

    Ok(repeated_workspace)
}

pub async fn update_workspace_request(
    token: &str,
    params: UpdateWorkspaceParams,
    url: &str,
) -> Result<(), ServerError> {
    let _ = request_builder()
        .patch(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn delete_workspace_request(token: &str, params: WorkspaceId, url: &str) -> Result<(), ServerError> {
    let _ = request_builder()
        .delete(url)
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

// App
pub async fn create_app_request(token: &str, params: CreateAppParams, url: &str) -> Result<App, ServerError> {
    let app = request_builder()
        .post(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .response()
        .await?;
    Ok(app)
}

pub async fn read_app_request(token: &str, params: AppId, url: &str) -> Result<Option<App>, ServerError> {
    let app = request_builder()
        .get(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .option_response()
        .await?;

    Ok(app)
}

pub async fn update_app_request(token: &str, params: UpdateAppParams, url: &str) -> Result<(), ServerError> {
    let _ = request_builder()
        .patch(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn delete_app_request(token: &str, params: AppId, url: &str) -> Result<(), ServerError> {
    let _ = request_builder()
        .delete(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

// View
pub async fn create_view_request(token: &str, params: CreateViewParams, url: &str) -> Result<View, ServerError> {
    let view = request_builder()
        .post(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .response()
        .await?;
    Ok(view)
}

pub async fn read_view_request(token: &str, params: ViewId, url: &str) -> Result<Option<View>, ServerError> {
    let view = request_builder()
        .get(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .option_response()
        .await?;

    Ok(view)
}

pub async fn update_view_request(token: &str, params: UpdateViewParams, url: &str) -> Result<(), ServerError> {
    let _ = request_builder()
        .patch(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn delete_view_request(token: &str, params: RepeatedViewId, url: &str) -> Result<(), ServerError> {
    let _ = request_builder()
        .delete(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn create_trash_request(token: &str, params: RepeatedTrashId, url: &str) -> Result<(), ServerError> {
    let _ = request_builder()
        .post(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn delete_trash_request(token: &str, params: RepeatedTrashId, url: &str) -> Result<(), ServerError> {
    let _ = request_builder()
        .delete(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn read_trash_request(token: &str, url: &str) -> Result<RepeatedTrash, ServerError> {
    let repeated_trash = request_builder()
        .get(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .response::<RepeatedTrash>()
        .await?;
    Ok(repeated_trash)
}

lazy_static! {
    static ref MIDDLEWARE: Arc<CoreResponseMiddleware> = Arc::new(CoreResponseMiddleware::new());
}

pub struct CoreResponseMiddleware {
    invalid_token_sender: broadcast::Sender<String>,
}

impl CoreResponseMiddleware {
    fn new() -> Self {
        let (sender, _) = broadcast::channel(10);
        CoreResponseMiddleware {
            invalid_token_sender: sender,
        }
    }

    #[allow(dead_code)]
    fn invalid_token_subscribe(&self) -> broadcast::Receiver<String> {
        self.invalid_token_sender.subscribe()
    }
}

impl ResponseMiddleware for CoreResponseMiddleware {
    fn receive_response(&self, token: &Option<String>, response: &FlowyResponse) {
        if let Some(error) = &response.error {
            if error.is_unauthorized() {
                tracing::error!("user is unauthorized");
                match token {
                    None => {}
                    Some(token) => match self.invalid_token_sender.send(token.clone()) {
                        Ok(_) => {}
                        Err(e) => tracing::error!("{:?}", e),
                    },
                }
            }
        }
    }
}
