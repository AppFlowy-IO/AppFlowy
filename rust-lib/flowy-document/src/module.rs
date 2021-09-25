use std::sync::Arc;

use diesel::SqliteConnection;
use parking_lot::RwLock;

use flowy_database::ConnectionPool;

use crate::{
    entities::doc::{CreateDocParams, Doc, DocDelta, QueryDocParams},
    errors::DocError,
    services::{doc::doc_controller::DocController, server::construct_doc_server, ws::WsDocumentManager},
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
    pub fn new(user: Arc<dyn DocumentUser>, ws_manager: Arc<RwLock<WsDocumentManager>>) -> FlowyDocument {
        let server = construct_doc_server();
        let controller = Arc::new(DocController::new(server.clone(), user.clone(), ws_manager.clone()));
        Self { doc_ctrl: controller }
    }

    pub fn create(&self, params: CreateDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let _ = self.doc_ctrl.create(params, conn)?;
        Ok(())
    }

    pub fn delete(&self, params: QueryDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let _ = self.doc_ctrl.delete(params, conn)?;
        Ok(())
    }

    pub async fn open(&self, params: QueryDocParams, pool: Arc<ConnectionPool>) -> Result<Doc, DocError> {
        let open_doc = self.doc_ctrl.open(params, pool).await?;
        Ok(open_doc.doc())
    }

    pub async fn apply_doc_delta(&self, params: DocDelta) -> Result<Doc, DocError> {
        // workaround: compare the rust's delta with flutter's delta. Will be removed
        // very soon
        let doc = self.doc_ctrl.edit_doc(params.clone())?;
        Ok(doc)
    }
}
