use std::sync::Arc;

use lazy_static::lazy_static;

use flowy_client_network_config::{ClientServerConfiguration, HEADER_TOKEN};
use flowy_error::FlowyError;

use crate::request::{HttpRequestBuilder, ResponseMiddleware};
use crate::response::HttpResponse;

pub struct DocumentCloudServiceImpl {
  config: ClientServerConfiguration,
}

impl DocumentCloudServiceImpl {
  pub fn new(config: ClientServerConfiguration) -> Self {
    Self { config }
  }
}

pub async fn create_document_request(
  token: &str,
  params: String,
  url: &str,
) -> Result<(), FlowyError> {
  request_builder()
    .post(url)
    .header(HEADER_TOKEN, token)
    .json(params)?
    .send()
    .await?;
  Ok(())
}

pub async fn read_document_request(
  _token: &str,
  _params: String,
  _url: &str,
) -> Result<Option<String>, FlowyError> {
  todo!()
}

pub async fn reset_doc_request(
  _token: &str,
  _params: String,
  _url: &str,
) -> Result<(), FlowyError> {
  // request_builder()
  //   .patch(url)
  //   .header(HEADER_TOKEN, token)
  //   .json(params)?
  //   .send()
  //   .await?;
  // Ok(())
  todo!()
}

fn request_builder() -> HttpRequestBuilder {
  HttpRequestBuilder::new().middleware(MIDDLEWARE.clone())
}

lazy_static! {
  pub(crate) static ref MIDDLEWARE: Arc<DocumentResponseMiddleware> =
    Arc::new(DocumentResponseMiddleware {});
}

pub(crate) struct DocumentResponseMiddleware {}
impl ResponseMiddleware for DocumentResponseMiddleware {
  fn receive_response(&self, token: &Option<String>, response: &HttpResponse) {
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
