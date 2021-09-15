use crate::{
    errors::DocError,
    services::{doc_cache::DocCache, server::construct_doc_server},
};

use crate::{
    entities::doc::{ApplyChangesetParams, CreateDocParams, Doc, QueryDocParams, SaveDocParams},
    services::doc_controller::DocController,
};
use diesel::SqliteConnection;
use flowy_database::ConnectionPool;
use flowy_ot::client::Document;
use std::sync::Arc;
use tokio::sync::RwLock;

pub trait DocumentUser: Send + Sync {
    fn user_doc_dir(&self) -> Result<String, DocError>;
    fn user_id(&self) -> Result<String, DocError>;
    fn token(&self) -> Result<String, DocError>;
}

pub struct FlowyDocument {
    controller: Arc<DocController>,
    cache: Arc<DocCache>,
}

impl FlowyDocument {
    pub fn new(user: Arc<dyn DocumentUser>) -> FlowyDocument {
        let server = construct_doc_server();
        let cache = Arc::new(DocCache::new());
        let controller = Arc::new(DocController::new(server.clone(), user.clone()));
        Self { controller, cache }
    }

    pub fn create(&self, params: CreateDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let _ = self.controller.create(params, conn)?;
        Ok(())
    }

    pub fn delete(&self, params: QueryDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let _ = self.cache.close(&params.doc_id)?;
        let _ = self.controller.delete(params.into(), conn)?;
        Ok(())
    }

    pub async fn open(&self, params: QueryDocParams, pool: Arc<ConnectionPool>) -> Result<Doc, DocError> {
        let doc = self.controller.open(params, pool).await?;
        let _ = self.cache.open(&doc.id, doc.data.clone())?;

        Ok(doc)
    }

    pub async fn update(&self, params: SaveDocParams, pool: Arc<ConnectionPool>) -> Result<(), DocError> {
        let _ = self.controller.update(params, &*pool.get().unwrap())?;
        Ok(())
    }

    pub async fn apply_changeset(&self, params: ApplyChangesetParams) -> Result<Doc, DocError> {
        let _ = self
            .cache
            .mut_doc(&params.id, |doc| {
                let _ = doc.apply_changeset(params.data.clone())?;
                Ok(())
            })
            .await?;

        let doc_str = match self.cache.read_doc(&params.id).await? {
            None => "".to_owned(),
            Some(doc_json) => doc_json,
        };

        let doc = Doc {
            id: params.id,
            data: doc_str.as_bytes().to_vec(),
        };

        Ok(doc)
    }
}
