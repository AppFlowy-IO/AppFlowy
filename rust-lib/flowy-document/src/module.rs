use crate::{
    errors::DocError,
    services::{doc_controller::DocController, doc_manager::DocManager, server::construct_doc_server},
};

use crate::entities::doc::{CreateDocParams, Doc, QueryDocParams, UpdateDocParams};
use diesel::SqliteConnection;
use flowy_database::ConnectionPool;
use std::sync::Arc;
use tokio::sync::RwLock;

pub trait DocumentUser: Send + Sync {
    fn user_doc_dir(&self) -> Result<String, DocError>;
    fn user_id(&self) -> Result<String, DocError>;
    fn token(&self) -> Result<String, DocError>;
}

pub enum DocumentType {
    Doc,
}

pub struct FlowyDocument {
    controller: Arc<DocController>,
    manager: Arc<DocManager>,
}

impl FlowyDocument {
    pub fn new(user: Arc<dyn DocumentUser>) -> FlowyDocument {
        let server = construct_doc_server();
        let manager = Arc::new(DocManager::new());
        let controller = Arc::new(DocController::new(server.clone(), user.clone()));
        Self { controller, manager }
    }

    pub fn create(&self, params: CreateDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let _ = self.controller.create(params, conn)?;
        Ok(())
    }

    pub fn delete(&self, params: QueryDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let _ = self.controller.delete(params.into(), conn)?;
        Ok(())
    }

    pub async fn open(&self, params: QueryDocParams, pool: Arc<ConnectionPool>) -> Result<Doc, DocError> {
        let doc = self.controller.open(params, pool).await?;

        Ok(doc)
    }

    pub fn update(&self, params: UpdateDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let _ = self.controller.update(params, conn)?;
        Ok(())
    }
}
