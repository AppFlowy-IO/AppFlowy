use crate::{
    configuration::{ClientServerConfiguration, HEADER_TOKEN},
    request::{HttpRequestBuilder, ResponseMiddleware},
};
use flowy_error::FlowyError;
use flowy_folder::entities::{
    trash::RepeatedTrashId,
    view::{CreateViewParams, RepeatedViewId, UpdateViewParams, ViewId},
    workspace::{CreateWorkspaceParams, UpdateWorkspaceParams, WorkspaceId},
    {AppId, CreateAppParams, UpdateAppParams},
};

use flowy_folder::event_map::FolderCouldServiceV1;
use flowy_folder_data_model::revision::{AppRevision, TrashRevision, ViewRevision, WorkspaceRevision};
use http_flowy::errors::ServerError;
use http_flowy::response::FlowyResponse;
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

    fn create_workspace(
        &self,
        token: &str,
        params: CreateWorkspaceParams,
    ) -> FutureResult<WorkspaceRevision, FlowyError> {
        let token = token.to_owned();
        let url = self.config.workspace_url();
        FutureResult::new(async move {
            let workspace = create_workspace_request(&token, params, &url).await?;
            Ok(workspace)
        })
    }

    fn read_workspace(&self, token: &str, params: WorkspaceId) -> FutureResult<Vec<WorkspaceRevision>, FlowyError> {
        let token = token.to_owned();
        let url = self.config.workspace_url();
        FutureResult::new(async move {
            let workspace_revs = read_workspaces_request(&token, params, &url).await?;
            Ok(workspace_revs)
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

    fn create_view(&self, token: &str, params: CreateViewParams) -> FutureResult<ViewRevision, FlowyError> {
        let token = token.to_owned();
        let url = self.config.view_url();
        FutureResult::new(async move {
            let view = create_view_request(&token, params, &url).await?;
            Ok(view)
        })
    }

    fn read_view(&self, token: &str, params: ViewId) -> FutureResult<Option<ViewRevision>, FlowyError> {
        let token = token.to_owned();
        let url = self.config.view_url();
        FutureResult::new(async move {
            let view_rev = read_view_request(&token, params, &url).await?;
            Ok(view_rev)
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

    fn create_app(&self, token: &str, params: CreateAppParams) -> FutureResult<AppRevision, FlowyError> {
        let token = token.to_owned();
        let url = self.config.app_url();
        FutureResult::new(async move {
            let app = create_app_request(&token, params, &url).await?;
            Ok(app)
        })
    }

    fn read_app(&self, token: &str, params: AppId) -> FutureResult<Option<AppRevision>, FlowyError> {
        let token = token.to_owned();
        let url = self.config.app_url();
        FutureResult::new(async move {
            let app_rev = read_app_request(&token, params, &url).await?;
            Ok(app_rev)
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

    fn read_trash(&self, token: &str) -> FutureResult<Vec<TrashRevision>, FlowyError> {
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
    _token: &str,
    _params: CreateWorkspaceParams,
    _url: &str,
) -> Result<WorkspaceRevision, ServerError> {
    // let workspace = request_builder()
    //     .post(&url.to_owned())
    //     .header(HEADER_TOKEN, token)
    //     .protobuf(params)?
    //     .response()
    //     .await?;
    // Ok(workspace)
    unimplemented!()
}

pub async fn read_workspaces_request(
    _token: &str,
    _params: WorkspaceId,
    _url: &str,
) -> Result<Vec<WorkspaceRevision>, ServerError> {
    // let repeated_workspace = request_builder()
    //     .get(&url.to_owned())
    //     .header(HEADER_TOKEN, token)
    //     .protobuf(params)?
    //     .response::<RepeatedWorkspace>()
    //     .await?;
    //
    // Ok(repeated_workspace)
    unimplemented!()
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
pub async fn create_app_request(
    _token: &str,
    _params: CreateAppParams,
    _url: &str,
) -> Result<AppRevision, ServerError> {
    // let app = request_builder()
    //     .post(&url.to_owned())
    //     .header(HEADER_TOKEN, token)
    //     .protobuf(params)?
    //     .response()
    //     .await?;
    // Ok(app)
    unimplemented!()
}

pub async fn read_app_request(_token: &str, _params: AppId, _url: &str) -> Result<Option<AppRevision>, ServerError> {
    // let app = request_builder()
    //     .get(&url.to_owned())
    //     .header(HEADER_TOKEN, token)
    //     .protobuf(params)?
    //     .option_response()
    //     .await?;
    // Ok(app)

    unimplemented!()
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
pub async fn create_view_request(
    _token: &str,
    _params: CreateViewParams,
    _url: &str,
) -> Result<ViewRevision, ServerError> {
    // let view = request_builder()
    //     .post(&url.to_owned())
    //     .header(HEADER_TOKEN, token)
    //     .protobuf(params)?
    //     .response()
    //     .await?;
    // Ok(view)
    unimplemented!()
}

pub async fn read_view_request(_token: &str, _params: ViewId, _url: &str) -> Result<Option<ViewRevision>, ServerError> {
    // let view = request_builder()
    //     .get(&url.to_owned())
    //     .header(HEADER_TOKEN, token)
    //     .protobuf(params)?
    //     .option_response()
    //     .await?;
    //
    // Ok(view)
    unimplemented!()
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

pub async fn read_trash_request(_token: &str, _url: &str) -> Result<Vec<TrashRevision>, ServerError> {
    // let repeated_trash = request_builder()
    //     .get(&url.to_owned())
    //     .header(HEADER_TOKEN, token)
    //     .response::<RepeatedTrash>()
    //     .await?;
    // Ok(repeated_trash)
    unimplemented!()
}

lazy_static! {
    static ref MIDDLEWARE: Arc<FolderResponseMiddleware> = Arc::new(FolderResponseMiddleware::new());
}

pub struct FolderResponseMiddleware {
    invalid_token_sender: broadcast::Sender<String>,
}

impl FolderResponseMiddleware {
    fn new() -> Self {
        let (sender, _) = broadcast::channel(10);
        FolderResponseMiddleware {
            invalid_token_sender: sender,
        }
    }

    #[allow(dead_code)]
    fn invalid_token_subscribe(&self) -> broadcast::Receiver<String> {
        self.invalid_token_sender.subscribe()
    }
}

impl ResponseMiddleware for FolderResponseMiddleware {
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
