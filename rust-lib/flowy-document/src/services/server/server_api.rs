use crate::{
    entities::doc::{CreateDocParams, Doc, QueryDocParams, UpdateDocParams},
    errors::DocError,
    services::server::DocumentServerAPI,
};
use flowy_infra::future::ResultFuture;
use flowy_net::{config::HEADER_TOKEN, request::HttpRequestBuilder};

pub struct DocServer {}

impl DocumentServerAPI for DocServer {
    fn create_doc(&self, token: &str, params: CreateDocParams) -> ResultFuture<Doc, DocError> { unimplemented!() }

    fn read_doc(&self, token: &str, params: QueryDocParams) -> ResultFuture<Option<Doc>, DocError> { unimplemented!() }

    fn update_doc(&self, token: &str, params: UpdateDocParams) -> ResultFuture<(), DocError> { unimplemented!() }

    fn delete_doc(&self, token: &str, params: QueryDocParams) -> ResultFuture<(), DocError> { unimplemented!() }
}

pub(crate) fn request_builder() -> HttpRequestBuilder { HttpRequestBuilder::new().middleware(super::middleware::MIDDLEWARE.clone()) }

pub async fn create_doc_request(token: &str, params: CreateDocParams, url: &str) -> Result<Doc, DocError> {
    let doc = request_builder()
        .post(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?
        .response()
        .await?;
    Ok(doc)
}
