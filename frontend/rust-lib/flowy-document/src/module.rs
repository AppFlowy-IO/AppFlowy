use crate::{
    errors::FlowyError,
    services::{
        controller::DocController,
        doc::{edit::ClientDocEditor, DocumentWsHandlers},
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

pub struct FlowyDocument {
    doc_ctrl: Arc<DocController>,
    user: Arc<dyn DocumentUser>,
}

impl FlowyDocument {
    pub fn new(
        user: Arc<dyn DocumentUser>,
        ws_manager: Arc<DocumentWsHandlers>,
        server_config: &ClientServerConfiguration,
    ) -> FlowyDocument {
        let server = construct_doc_server(server_config);
        let doc_ctrl = Arc::new(DocController::new(server, user.clone(), ws_manager));
        Self { doc_ctrl, user }
    }

    pub fn init(&self) -> Result<(), FlowyError> {
        let _ = self.doc_ctrl.init()?;
        Ok(())
    }

    pub fn delete(&self, params: DocIdentifier) -> Result<(), FlowyError> {
        let _ = self.doc_ctrl.delete(params)?;
        Ok(())
    }

    pub async fn open(&self, params: DocIdentifier) -> Result<Arc<ClientDocEditor>, FlowyError> {
        let edit_context = self.doc_ctrl.open(params, self.user.db_pool()?).await?;
        Ok(edit_context)
    }

    pub async fn close(&self, params: DocIdentifier) -> Result<(), FlowyError> {
        let _ = self.doc_ctrl.close(&params.doc_id)?;
        Ok(())
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

    pub async fn apply_doc_delta(&self, params: DocumentDelta) -> Result<DocumentDelta, FlowyError> {
        // workaround: compare the rust's delta with flutter's delta. Will be removed
        // very soon
        let doc = self
            .doc_ctrl
            .apply_local_delta(params.clone(), self.user.db_pool()?)
            .await?;
        Ok(doc)
    }
}
