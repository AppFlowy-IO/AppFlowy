use crate::{
    services::doc::ws_actor::{DocWsActor, DocWsMsg},
    web_socket::{WsBizHandler, WsClientData},
};
use actix_web::web::Data;
use flowy_collaboration::core::sync::DocManager;
use sqlx::PgPool;
use std::sync::Arc;
use tokio::sync::{mpsc, oneshot};

pub struct DocumentCore {
    pub manager: Arc<DocManager>,
    ws_sender: mpsc::Sender<DocWsMsg>,
    pg_pool: Data<PgPool>,
}

impl DocumentCore {
    pub fn new(pg_pool: Data<PgPool>) -> Self {
        let manager = Arc::new(DocManager::new());
        let (ws_sender, rx) = mpsc::channel(100);
        let actor = DocWsActor::new(rx, manager.clone());
        tokio::task::spawn(actor.run());
        Self {
            manager,
            ws_sender,
            pg_pool,
        }
    }
}

impl WsBizHandler for DocumentCore {
    fn receive(&self, data: WsClientData) {
        let (ret, rx) = oneshot::channel();
        let sender = self.ws_sender.clone();
        let pool = self.pg_pool.clone();

        actix_rt::spawn(async move {
            let msg = DocWsMsg::ClientData {
                client_data: data,
                ret,
                pool,
            };
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
