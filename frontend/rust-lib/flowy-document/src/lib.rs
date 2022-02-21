pub mod editor;
pub mod manager;
mod queue;
mod web_socket;

pub use manager::*;
pub mod errors {
    pub use flowy_error::{internal_error, ErrorCode, FlowyError};
}

pub const DOCUMENT_SYNC_INTERVAL_IN_MILLIS: u64 = 1000;

use crate::errors::FlowyError;
use flowy_collaboration::entities::document_info::{CreateDocParams, DocumentId, DocumentInfo, ResetDocumentParams};
use lib_infra::future::FutureResult;

pub trait DocumentCloudService: Send + Sync {
    fn create_document(&self, token: &str, params: CreateDocParams) -> FutureResult<(), FlowyError>;

    fn read_document(&self, token: &str, params: DocumentId) -> FutureResult<Option<DocumentInfo>, FlowyError>;

    fn update_document(&self, token: &str, params: ResetDocumentParams) -> FutureResult<(), FlowyError>;
}
