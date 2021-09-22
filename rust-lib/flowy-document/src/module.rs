use crate::{
    entities::doc::{ApplyChangesetParams, CreateDocParams, Doc, QueryDocParams},
    errors::DocError,
    services::{doc_controller::DocController, open_doc::OpenedDocManager, server::construct_doc_server, ws::WsManager},
};
use bytes::Bytes;
use diesel::SqliteConnection;
use flowy_database::ConnectionPool;
use parking_lot::RwLock;
use std::sync::Arc;

pub trait DocumentUser: Send + Sync {
    fn user_dir(&self) -> Result<String, DocError>;
    fn user_id(&self) -> Result<String, DocError>;
    fn token(&self) -> Result<String, DocError>;
}

pub struct FlowyDocument {
    controller: Arc<DocController>,
    doc_manager: Arc<OpenedDocManager>,
}

impl FlowyDocument {
    pub fn new(user: Arc<dyn DocumentUser>, ws_manager: Arc<RwLock<WsManager>>) -> FlowyDocument {
        let server = construct_doc_server();
        let controller = Arc::new(DocController::new(server.clone(), user.clone()));
        let doc_manager = Arc::new(OpenedDocManager::new(ws_manager, controller.clone()));

        Self { controller, doc_manager }
    }

    pub fn create(&self, params: CreateDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let _ = self.controller.create(params, conn)?;
        Ok(())
    }

    pub fn delete(&self, params: QueryDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let _ = self.doc_manager.close(&params.doc_id)?;
        let _ = self.controller.delete(params.into(), conn)?;
        Ok(())
    }

    pub async fn open(&self, params: QueryDocParams, pool: Arc<ConnectionPool>) -> Result<Doc, DocError> {
        let doc = match self.doc_manager.is_opened(&params.doc_id) {
            true => {
                let data = self.doc_manager.read_doc(&params.doc_id).await?;
                Doc { id: params.doc_id, data }
            },
            false => {
                let doc = self.controller.open(params, pool).await?;
                let _ = self.doc_manager.open(&doc.id, doc.data.clone())?;
                doc
            },
        };

        Ok(doc)
    }

    pub async fn apply_changeset(&self, params: ApplyChangesetParams, pool: Arc<ConnectionPool>) -> Result<Doc, DocError> {
        let _ = self.doc_manager.apply_changeset(&params.id, Bytes::from(params.data), pool).await?;
        let data = self.doc_manager.read_doc(&params.id).await?;
        let doc = Doc { id: params.id, data };
        Ok(doc)
    }
}
