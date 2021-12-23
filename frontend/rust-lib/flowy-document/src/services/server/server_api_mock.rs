use flowy_collaboration::{
    core::document::default::initial_delta_string,
    entities::doc::{CreateDocParams, Doc, DocIdentifier, ResetDocumentParams},
};
use lib_infra::future::FutureResult;

use crate::{errors::FlowyError, services::server::DocumentServerAPI};

pub struct DocServerMock {}

impl DocumentServerAPI for DocServerMock {
    fn create_doc(&self, _token: &str, _params: CreateDocParams) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn read_doc(&self, _token: &str, params: DocIdentifier) -> FutureResult<Option<Doc>, FlowyError> {
        let doc = Doc {
            id: params.doc_id,
            text: initial_delta_string(),
            rev_id: 0,
            base_rev_id: 0,
        };
        FutureResult::new(async { Ok(Some(doc)) })
    }

    fn update_doc(&self, _token: &str, _params: ResetDocumentParams) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }
}
