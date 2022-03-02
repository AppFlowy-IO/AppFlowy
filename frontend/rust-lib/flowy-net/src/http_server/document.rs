use crate::{
    configuration::*,
    request::{HttpRequestBuilder, ResponseMiddleware},
};
use flowy_block::BlockCloudService;
use flowy_collaboration::entities::document_info::{BlockId, BlockInfo, CreateBlockParams, ResetDocumentParams};
use flowy_error::FlowyError;
use http_flowy::response::FlowyResponse;
use lazy_static::lazy_static;
use lib_infra::future::FutureResult;
use std::sync::Arc;

pub struct BlockHttpCloudService {
    config: ClientServerConfiguration,
}

impl BlockHttpCloudService {
    pub fn new(config: ClientServerConfiguration) -> Self {
        Self { config }
    }
}

impl BlockCloudService for BlockHttpCloudService {
    fn create_block(&self, token: &str, params: CreateBlockParams) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.doc_url();
        FutureResult::new(async move { create_document_request(&token, params, &url).await })
    }

    fn read_block(&self, token: &str, params: BlockId) -> FutureResult<Option<BlockInfo>, FlowyError> {
        let token = token.to_owned();
        let url = self.config.doc_url();
        FutureResult::new(async move { read_document_request(&token, params, &url).await })
    }

    fn update_block(&self, token: &str, params: ResetDocumentParams) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.doc_url();
        FutureResult::new(async move { reset_doc_request(&token, params, &url).await })
    }
}

pub async fn create_document_request(token: &str, params: CreateBlockParams, url: &str) -> Result<(), FlowyError> {
    let _ = request_builder()
        .post(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn read_document_request(token: &str, params: BlockId, url: &str) -> Result<Option<BlockInfo>, FlowyError> {
    let doc = request_builder()
        .get(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .option_response()
        .await?;

    Ok(doc)
}

pub async fn reset_doc_request(token: &str, params: ResetDocumentParams, url: &str) -> Result<(), FlowyError> {
    let _ = request_builder()
        .patch(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

fn request_builder() -> HttpRequestBuilder {
    HttpRequestBuilder::new().middleware(MIDDLEWARE.clone())
}

lazy_static! {
    pub(crate) static ref MIDDLEWARE: Arc<DocumentResponseMiddleware> = Arc::new(DocumentResponseMiddleware {});
}

pub(crate) struct DocumentResponseMiddleware {}
impl ResponseMiddleware for DocumentResponseMiddleware {
    fn receive_response(&self, token: &Option<String>, response: &FlowyResponse) {
        if let Some(error) = &response.error {
            if error.is_unauthorized() {
                tracing::error!("document user is unauthorized");

                match token {
                    None => {}
                    Some(_token) => {
                        // let error =
                        // FlowyError::new(ErrorCode::UserUnauthorized, "");
                        // observable(token,
                        // WorkspaceObservable::UserUnauthorized).error(error).
                        // build()
                    }
                }
            }
        }
    }
}
