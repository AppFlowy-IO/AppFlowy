use crate::{
    entities::doc::{CreateDocParams, Doc, QueryDocParams, UpdateDocParams},
    errors::DocError,
    services::server::DocumentServerAPI,
};
use flowy_infra::future::ResultFuture;
pub struct DocServerMock {}

impl DocumentServerAPI for DocServerMock {
    fn create_doc(&self, _token: &str, _params: CreateDocParams) -> ResultFuture<(), DocError> {
        ResultFuture::new(async { Ok(()) })
    }

    fn read_doc(&self, _token: &str, _params: QueryDocParams) -> ResultFuture<Option<Doc>, DocError> {
        ResultFuture::new(async { Ok(None) })
    }

    fn update_doc(&self, _token: &str, _params: UpdateDocParams) -> ResultFuture<(), DocError> {
        ResultFuture::new(async { Ok(()) })
    }

    fn delete_doc(&self, _token: &str, _params: QueryDocParams) -> ResultFuture<(), DocError> {
        ResultFuture::new(async { Ok(()) })
    }
}
