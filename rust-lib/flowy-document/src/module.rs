use crate::{
    entities::doc::{CreateDocParams, Doc, DocChangeset, QueryDocParams},
    errors::DocError,
    services::{doc_controller::DocController, server::construct_doc_server, ws::WsManager},
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
}

impl FlowyDocument {
    pub fn new(user: Arc<dyn DocumentUser>, ws_manager: Arc<RwLock<WsManager>>) -> FlowyDocument {
        let server = construct_doc_server();
        let controller = Arc::new(DocController::new(server.clone(), user.clone(), ws_manager.clone()));
        Self { controller }
    }

    pub fn create(&self, params: CreateDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let _ = self.controller.create(params, conn)?;
        Ok(())
    }

    pub fn delete(&self, params: QueryDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let _ = self.controller.delete(params, conn)?;
        Ok(())
    }

    pub async fn open(&self, params: QueryDocParams, pool: Arc<ConnectionPool>) -> Result<Doc, DocError> {
        let open_doc = self.controller.open(params, pool).await?;
        Ok(open_doc.doc())
    }

    pub async fn apply_changeset(&self, params: DocChangeset, pool: Arc<ConnectionPool>) -> Result<Doc, DocError> {
        // let _ = self.doc_manager.apply_changeset(&params.id,
        // Bytes::from(params.data), pool).await?;
        //
        // // workaround: compare the rust's delta with flutter's delta. Will be removed
        // // very soon
        // let doc = self.doc_manager.read_doc(&params.id)?;
        // Ok(doc)
        unimplemented!()
    }
}
