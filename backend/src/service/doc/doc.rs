use crate::service::{
    doc::{
        actor::{DocWsMsg, DocWsMsgActor},
        edit::EditDoc,
        read_doc,
    },
    ws::{WsBizHandler, WsClientData},
};
use actix_web::web::Data;
use dashmap::DashMap;
use flowy_document::protobuf::QueryDocParams;
use flowy_net::errors::{internal_error, ServerError};
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
        let actor = DocWsMsgActor::new(rx, manager.clone());
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
    docs_map: DashMap<String, Arc<EditDoc>>,
}

impl DocManager {
    pub fn new() -> Self {
        Self {
            docs_map: DashMap::new(),
        }
    }

    pub async fn get(&self, doc_id: &str, pg_pool: Data<PgPool>) -> Result<Option<Arc<EditDoc>>, ServerError> {
        match self.docs_map.get(doc_id) {
            None => {
                let params = QueryDocParams {
                    doc_id: doc_id.to_string(),
                    ..Default::default()
                };
                let doc = read_doc(pg_pool.get_ref(), params).await?;
                let edit_doc = spawn_blocking(|| EditDoc::new(doc)).await.map_err(internal_error)?;
                let edit_doc = Arc::new(edit_doc?);
                self.docs_map.insert(doc_id.to_string(), edit_doc.clone());
                Ok(Some(edit_doc))
            },
            Some(ctx) => Ok(Some(ctx.clone())),
        }
    }
}
