use crate::service::{
    doc::{
        edit::DocHandle,
        read_doc,
        ws_actor::{DocWsActor, DocWsMsg},
    },
    ws::{WsBizHandler, WsClientData},
};
use actix_web::web::Data;
use backend_service::errors::{internal_error, ServerError};
use dashmap::DashMap;
use flowy_document_infra::protobuf::DocIdentifier;
use sqlx::PgPool;
use std::sync::Arc;
use tokio::{
    sync::{mpsc, oneshot},
    task::spawn_blocking,
};

pub struct DocBiz {
    pub manager: Arc<DocManager>,
    sender: mpsc::Sender<DocWsMsg>,
    pg_pool: Data<PgPool>,
}

impl DocBiz {
    pub fn new(pg_pool: Data<PgPool>) -> Self {
        let manager = Arc::new(DocManager::new());
        let (tx, rx) = mpsc::channel(100);
        let actor = DocWsActor::new(rx, manager.clone());
        tokio::task::spawn(actor.run());
        Self {
            manager,
            sender: tx,
            pg_pool,
        }
    }
}

impl WsBizHandler for DocBiz {
    fn receive_data(&self, client_data: WsClientData) {
        let (ret, rx) = oneshot::channel();
        let sender = self.sender.clone();
        let pool = self.pg_pool.clone();

        actix_rt::spawn(async move {
            let msg = DocWsMsg::ClientData { client_data, ret, pool };
            match sender.send(msg).await {
                Ok(_) => {},
                Err(e) => log::error!("{}", e),
            }
            match rx.await {
                Ok(_) => {},
                Err(e) => log::error!("{:?}", e),
            };
        });
    }
}

pub struct DocManager {
    docs_map: DashMap<String, Arc<DocHandle>>,
}

impl DocManager {
    pub fn new() -> Self {
        Self {
            docs_map: DashMap::new(),
        }
    }

    pub async fn get(&self, doc_id: &str, pg_pool: Data<PgPool>) -> Result<Option<Arc<DocHandle>>, ServerError> {
        match self.docs_map.get(doc_id) {
            None => {
                let params = DocIdentifier {
                    doc_id: doc_id.to_string(),
                    ..Default::default()
                };
                let doc = read_doc(pg_pool.get_ref(), params).await?;
                let handle = spawn_blocking(|| DocHandle::new(doc, pg_pool))
                    .await
                    .map_err(internal_error)?;
                let handle = Arc::new(handle?);
                self.docs_map.insert(doc_id.to_string(), handle.clone());
                Ok(Some(handle))
            },
            Some(ctx) => Ok(Some(ctx.clone())),
        }
    }
}
