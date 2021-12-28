use crate::{
    errors::FlowyError,
    services::{
        controller::DocController,
        doc::{edit::ClientDocEditor, DocumentWSReceivers, DocumentWebSocket},
        server::construct_doc_server,
    },
};
use backend_service::configuration::ClientServerConfiguration;
use flowy_collaboration::entities::doc::{DocIdentifier, DocumentDelta};
use flowy_database::ConnectionPool;
use std::sync::Arc;

pub trait DocumentUser: Send + Sync {
    fn user_dir(&self) -> Result<String, FlowyError>;
    fn user_id(&self) -> Result<String, FlowyError>;
    fn token(&self) -> Result<String, FlowyError>;
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError>;
}

pub struct DocumentContext {
    pub doc_ctrl: Arc<DocController>,
    pub user: Arc<dyn DocumentUser>,
}

impl DocumentContext {
    pub fn new(
        user: Arc<dyn DocumentUser>,
        ws_receivers: Arc<DocumentWSReceivers>,
        ws_sender: Arc<dyn DocumentWebSocket>,
        server_config: &ClientServerConfiguration,
    ) -> DocumentContext {
        let server = construct_doc_server(server_config);
        let doc_ctrl = Arc::new(DocController::new(server, user.clone(), ws_receivers, ws_sender));
        Self { doc_ctrl, user }
    }

    pub fn init(&self) -> Result<(), FlowyError> {
        let _ = self.doc_ctrl.init()?;
        Ok(())
    }

    pub async fn open(&self, params: DocIdentifier) -> Result<Arc<ClientDocEditor>, FlowyError> {
        let edit_context = self.doc_ctrl.open(params, self.user.db_pool()?).await?;
        Ok(edit_context)
    }

    pub async fn read_document_data(
        &self,
        params: DocIdentifier,
        pool: Arc<ConnectionPool>,
    ) -> Result<DocumentDelta, FlowyError> {
        let edit_context = self.doc_ctrl.open(params, pool).await?;
        let delta = edit_context.delta().await?;
        Ok(delta)
    }
}
