use crate::{errors::DocError, services::server::DocumentServerAPI};
use flowy_document_infra::entities::doc::{CreateDocParams, Doc, DocIdentifier, UpdateDocParams};
use flowy_net::{config::*, request::HttpRequestBuilder};
use lib_infra::future::ResultFuture;

pub struct DocServer {
    config: ServerConfig,
}

impl DocServer {
    pub fn new(config: ServerConfig) -> Self { Self { config } }
}

impl DocumentServerAPI for DocServer {
    fn create_doc(&self, token: &str, params: CreateDocParams) -> ResultFuture<(), DocError> {
        let token = token.to_owned();
        let url = self.config.doc_url();
        ResultFuture::new(async move { create_doc_request(&token, params, &url).await })
    }

    fn read_doc(&self, token: &str, params: DocIdentifier) -> ResultFuture<Option<Doc>, DocError> {
        let token = token.to_owned();
        let url = self.config.doc_url();
        ResultFuture::new(async move { read_doc_request(&token, params, &url).await })
    }

    fn update_doc(&self, token: &str, params: UpdateDocParams) -> ResultFuture<(), DocError> {
        let token = token.to_owned();
        let url = self.config.doc_url();
        ResultFuture::new(async move { update_doc_request(&token, params, &url).await })
    }
}

pub(crate) fn request_builder() -> HttpRequestBuilder {
    HttpRequestBuilder::new().middleware(super::middleware::MIDDLEWARE.clone())
}

pub async fn create_doc_request(token: &str, params: CreateDocParams, url: &str) -> Result<(), DocError> {
    let _ = request_builder()
        .post(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn read_doc_request(token: &str, params: DocIdentifier, url: &str) -> Result<Option<Doc>, DocError> {
    let doc = request_builder()
        .get(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .option_response()
        .await?;

    Ok(doc)
}

pub async fn update_doc_request(token: &str, params: UpdateDocParams, url: &str) -> Result<(), DocError> {
    let _ = request_builder()
        .patch(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}
