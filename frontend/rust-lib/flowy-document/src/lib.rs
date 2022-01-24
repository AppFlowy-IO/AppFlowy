pub mod controller;
pub mod core;
// mod notify;
pub mod protobuf;
pub use controller::*;
pub mod errors {
    pub use flowy_error::{internal_error, ErrorCode, FlowyError};
}

use crate::errors::FlowyError;
use flowy_collaboration::entities::document_info::{CreateDocParams, DocumentId, DocumentInfo, ResetDocumentParams};
use lib_infra::future::FutureResult;

pub trait DocumentCloudService: Send + Sync {
    fn create_document(&self, token: &str, params: CreateDocParams) -> FutureResult<(), FlowyError>;

    fn read_document(&self, token: &str, params: DocumentId) -> FutureResult<Option<DocumentInfo>, FlowyError>;

    fn update_document(&self, token: &str, params: ResetDocumentParams) -> FutureResult<(), FlowyError>;
}
