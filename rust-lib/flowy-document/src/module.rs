use std::sync::Arc;

use diesel::SqliteConnection;

use flowy_database::ConnectionPool;
use flowy_net::config::ServerConfig;

use crate::{
    entities::doc::{CreateDocParams, Doc, DocDelta, QueryDocParams},
    errors::DocError,
    services::{
        doc::{doc_controller::DocController, edit::ClientEditDoc},
        server::construct_doc_server,
        ws::WsDocumentManager,
    },
};

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

    pub fn create(&self, params: CreateDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let _ = self.doc_ctrl.create(params, conn)?;
        Ok(())
    }

    pub fn delete(&self, params: QueryDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let _ = self.doc_ctrl.delete(params, conn)?;
        Ok(())
    }

    pub async fn open(
        &self,
        params: QueryDocParams,
        pool: Arc<ConnectionPool>,
    ) -> Result<Arc<ClientEditDoc>, DocError> {
        let edit_context = self.doc_ctrl.open(params, pool).await?;
        Ok(edit_context)
    }

    pub async fn apply_doc_delta(&self, params: DocDelta) -> Result<Doc, DocError> {
        // workaround: compare the rust's delta with flutter's delta. Will be removed
        // very soon
        let doc = self.doc_ctrl.edit_doc(params.clone()).await?;
        Ok(doc)
    }
}
