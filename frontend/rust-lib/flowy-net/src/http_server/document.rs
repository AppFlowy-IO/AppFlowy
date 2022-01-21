use backend_service::{
    configuration::*,
    request::{HttpRequestBuilder, ResponseMiddleware},
    response::FlowyResponse,
};
use flowy_collaboration::entities::document_info::{CreateDocParams, DocumentId, DocumentInfo, ResetDocumentParams};
use flowy_document::DocumentCloudService;
use flowy_error::FlowyError;
use lazy_static::lazy_static;
use lib_infra::future::FutureResult;
use std::sync::Arc;

pub struct DocumentHttpCloudService {
    config: ClientServerConfiguration,
}

impl DocumentHttpCloudService {
    pub fn new(config: ClientServerConfiguration) -> Self { Self { config } }
}

impl DocumentCloudService for DocumentHttpCloudService {
    fn create_document(&self, token: &str, params: CreateDocParams) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.doc_url();
        FutureResult::new(async move { create_document_request(&token, params, &url).await })
    }

    fn read_document(&self, token: &str, params: DocumentId) -> FutureResult<Option<DocumentInfo>, FlowyError> {
        let token = token.to_owned();
        let url = self.config.doc_url();
        FutureResult::new(async move { read_document_request(&token, params, &url).await })
    }

    fn update_document(&self, token: &str, params: ResetDocumentParams) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.doc_url();
        FutureResult::new(async move { reset_doc_request(&token, params, &url).await })
    }
}

pub async fn create_document_request(token: &str, params: CreateDocParams, url: &str) -> Result<(), FlowyError> {
    let _ = request_builder()
        .post(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn read_document_request(
    token: &str,
    params: DocumentId,
    url: &str,
) -> Result<Option<DocumentInfo>, FlowyError> {
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

fn request_builder() -> HttpRequestBuilder { HttpRequestBuilder::new().middleware(MIDDLEWARE.clone()) }

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
                    None => {},
                    Some(_token) => {
                        // let error =
                        // FlowyError::new(ErrorCode::UserUnauthorized, "");
                        // observable(token,
                        // WorkspaceObservable::UserUnauthorized).error(error).
                        // build()
                    },
                }
            }
        }
    }
}
