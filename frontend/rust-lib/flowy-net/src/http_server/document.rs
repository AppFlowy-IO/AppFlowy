use crate::{
    configuration::*,
    request::{HttpRequestBuilder, ResponseMiddleware},
};
use flowy_document::DocumentCloudService;
use flowy_error::FlowyError;
use flowy_http_model::document::{CreateDocumentParams, DocumentId, DocumentPayload, ResetDocumentParams};
use http_flowy::response::FlowyResponse;
use lazy_static::lazy_static;
use lib_infra::future::FutureResult;
use std::sync::Arc;

pub struct DocumentCloudServiceImpl {
    config: ClientServerConfiguration,
}

impl DocumentCloudServiceImpl {
    pub fn new(config: ClientServerConfiguration) -> Self {
        Self { config }
    }
}

impl DocumentCloudService for DocumentCloudServiceImpl {
    fn create_document(&self, token: &str, params: CreateDocumentParams) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.doc_url();
        FutureResult::new(async move { create_document_request(&token, params, &url).await })
    }

    fn fetch_document(&self, token: &str, params: DocumentId) -> FutureResult<Option<DocumentPayload>, FlowyError> {
        let token = token.to_owned();
        let url = self.config.doc_url();
        FutureResult::new(async move { read_document_request(&token, params, &url).await })
    }

    fn update_document_content(&self, token: &str, params: ResetDocumentParams) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.doc_url();
        FutureResult::new(async move { reset_doc_request(&token, params, &url).await })
    }
}

pub async fn create_document_request(token: &str, params: CreateDocumentParams, url: &str) -> Result<(), FlowyError> {
    request_builder()
        .post(url)
        .header(HEADER_TOKEN, token)
        .json(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn read_document_request(
    token: &str,
    params: DocumentId,
    url: &str,
) -> Result<Option<DocumentPayload>, FlowyError> {
    let doc = request_builder()
        .get(url)
        .header(HEADER_TOKEN, token)
        .json(params)?
        .option_json_response()
        .await?;

    Ok(doc)
}

pub async fn reset_doc_request(token: &str, params: ResetDocumentParams, url: &str) -> Result<(), FlowyError> {
    request_builder()
        .patch(url)
        .header(HEADER_TOKEN, token)
        .json(params)?
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
