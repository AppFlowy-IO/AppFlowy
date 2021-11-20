use crate::{errors::DocError, services::server::DocumentServerAPI};
use flowy_document_infra::{
    entities::doc::{CreateDocParams, Doc, DocIdentifier, UpdateDocParams},
    user_default::doc_initial_string,
};
use lib_infra::future::ResultFuture;

pub struct DocServerMock {}

impl DocumentServerAPI for DocServerMock {
    fn create_doc(&self, _token: &str, _params: CreateDocParams) -> ResultFuture<(), DocError> {
        ResultFuture::new(async { Ok(()) })
    }

    fn read_doc(&self, _token: &str, params: DocIdentifier) -> ResultFuture<Option<Doc>, DocError> {
        let doc = Doc {
            id: params.doc_id,
            data: doc_initial_string(),
            rev_id: 0,
            base_rev_id: 0,
        };
        ResultFuture::new(async { Ok(Some(doc)) })
    }

    fn update_doc(&self, _token: &str, _params: UpdateDocParams) -> ResultFuture<(), DocError> {
        ResultFuture::new(async { Ok(()) })
    }
}
