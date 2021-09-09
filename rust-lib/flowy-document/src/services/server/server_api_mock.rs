use crate::{
    entities::doc::{CreateDocParams, Doc, QueryDocParams, UpdateDocParams},
    errors::DocError,
    services::server::DocumentServerAPI,
};
use flowy_infra::{future::ResultFuture, uuid};
pub struct DocServerMock {}

impl DocumentServerAPI for DocServerMock {
    fn create_doc(&self, _token: &str, _params: CreateDocParams) -> ResultFuture<Doc, DocError> {
        let uuid = uuid();
        let doc = Doc {
            id: uuid,
            data: "".to_string(),
        };

        ResultFuture::new(async { Ok(doc) })
    }

    fn read_doc(&self, _token: &str, _params: QueryDocParams) -> ResultFuture<Option<Doc>, DocError> {
        ResultFuture::new(async { Ok(None) })
    }

    fn update_doc(&self, _token: &str, _params: UpdateDocParams) -> ResultFuture<(), DocError> { ResultFuture::new(async { Ok(()) }) }

    fn delete_doc(&self, _token: &str, _params: QueryDocParams) -> ResultFuture<(), DocError> { ResultFuture::new(async { Ok(()) }) }
}
