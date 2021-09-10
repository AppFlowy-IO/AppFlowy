use crate::{
    entities::doc::{CreateDocParams, Doc, QueryDocParams, UpdateDocParams},
    errors::DocError,
    services::server::DocumentServerAPI,
};
use flowy_infra::future::ResultFuture;
use flowy_net::{config::*, request::HttpRequestBuilder};

pub struct DocServer {}

impl DocumentServerAPI for DocServer {
    fn create_doc(&self, token: &str, params: CreateDocParams) -> ResultFuture<(), DocError> {
        let token = token.to_owned();
        ResultFuture::new(async move { create_doc_request(&token, params, DOC_URL.as_ref()).await })
    }

    fn read_doc(&self, token: &str, params: QueryDocParams) -> ResultFuture<Option<Doc>, DocError> {
        let token = token.to_owned();
        ResultFuture::new(async move { read_doc_request(&token, params, DOC_URL.as_ref()).await })
    }

    fn update_doc(&self, token: &str, params: UpdateDocParams) -> ResultFuture<(), DocError> {
        let token = token.to_owned();
        ResultFuture::new(async move { update_doc_request(&token, params, DOC_URL.as_ref()).await })
    }

    fn delete_doc(&self, token: &str, params: QueryDocParams) -> ResultFuture<(), DocError> {
        let token = token.to_owned();
        ResultFuture::new(async move { delete_doc_request(&token, params, DOC_URL.as_ref()).await })
    }
}

pub(crate) fn request_builder() -> HttpRequestBuilder { HttpRequestBuilder::new().middleware(super::middleware::MIDDLEWARE.clone()) }

pub async fn create_doc_request(token: &str, params: CreateDocParams, url: &str) -> Result<(), DocError> {
    let _ = request_builder()
        .post(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn read_doc_request(token: &str, params: QueryDocParams, url: &str) -> Result<Option<Doc>, DocError> {
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

pub async fn delete_doc_request(token: &str, params: QueryDocParams, url: &str) -> Result<(), DocError> {
    let _ = request_builder()
        .delete(url)
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}
