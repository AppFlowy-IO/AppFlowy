use crate::{
    entities::doc::{DocDelta, DocIdentifier},
    errors::DocError,
    services::{
        doc::{doc_controller::DocController, edit::ClientEditDoc},
        server::construct_doc_server,
        ws::WsDocumentManager,
    },
};
use flowy_database::ConnectionPool;
use flowy_net::config::ServerConfig;
use std::sync::Arc;

pub trait DocumentUser: Send + Sync {
    fn user_dir(&self) -> Result<String, DocError>;
    fn user_id(&self) -> Result<String, DocError>;
    fn token(&self) -> Result<String, DocError>;
}

pub struct FlowyDocument {
    doc_ctrl: Arc<DocController>,
}

impl FlowyDocument {
    pub fn new(
        user: Arc<dyn DocumentUser>,
        ws_manager: Arc<WsDocumentManager>,
        server_config: &ServerConfig,
    ) -> FlowyDocument {
        let server = construct_doc_server(server_config);
        let controller = Arc::new(DocController::new(server.clone(), user.clone(), ws_manager.clone()));
        Self { doc_ctrl: controller }
    }

    pub fn init(&self) -> Result<(), DocError> {
        let _ = self.doc_ctrl.init()?;
        Ok(())
    }

    pub fn delete(&self, params: DocIdentifier) -> Result<(), DocError> {
        let _ = self.doc_ctrl.delete(params)?;
        Ok(())
    }

    pub async fn open(&self, params: DocIdentifier, pool: Arc<ConnectionPool>) -> Result<Arc<ClientEditDoc>, DocError> {
        let edit_context = self.doc_ctrl.open(params, pool).await?;
        Ok(edit_context)
    }

    pub async fn close(&self, params: DocIdentifier) -> Result<(), DocError> {
        let _ = self.doc_ctrl.close(&params.doc_id)?;
        Ok(())
    }

    pub async fn apply_doc_delta(&self, params: DocDelta) -> Result<DocDelta, DocError> {
        // workaround: compare the rust's delta with flutter's delta. Will be removed
        // very soon
        let doc = self.doc_ctrl.edit_doc(params.clone()).await?;
        Ok(doc)
    }
}
