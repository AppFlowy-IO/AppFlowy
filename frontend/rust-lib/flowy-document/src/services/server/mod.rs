mod middleware;
mod server_api;
mod server_api_mock;

pub use server_api::*;
// TODO: ignore mock files in production
use crate::errors::FlowyError;
use backend_service::configuration::ClientServerConfiguration;
use flowy_collaboration::entities::doc::{CreateDocParams, Doc, DocIdentifier, ResetDocumentParams};
use lib_infra::future::FutureResult;
pub use server_api_mock::*;
use std::sync::Arc;

pub(crate) type Server = Arc<dyn DocumentServerAPI + Send + Sync>;
pub trait DocumentServerAPI {
    fn create_doc(&self, token: &str, params: CreateDocParams) -> FutureResult<(), FlowyError>;

    fn read_doc(&self, token: &str, params: DocIdentifier) -> FutureResult<Option<Doc>, FlowyError>;

    fn update_doc(&self, token: &str, params: ResetDocumentParams) -> FutureResult<(), FlowyError>;
}

pub(crate) fn construct_doc_server(
    server_config: &ClientServerConfiguration,
) -> Arc<dyn DocumentServerAPI + Send + Sync> {
    if cfg!(feature = "http_server") {
        Arc::new(DocServer::new(server_config.clone()))
    } else {
        Arc::new(DocServerMock {})
    }
}
