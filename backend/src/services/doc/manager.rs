use crate::{
    services::doc::{
        edit::edit_actor::{EditDocActor, EditMsg},
        read_doc,
        ws_actor::{DocWsActor, DocWsMsg},
    },
    web_socket::{entities::Socket, WsBizHandler, WsClientData, WsUser},
};
use actix_web::web::Data;
use backend_service::errors::{internal_error, Result as DocResult, ServerError};
use dashmap::DashMap;
use flowy_collaboration::protobuf::{Doc, DocIdentifier};
use lib_ot::protobuf::Revision;
use sqlx::PgPool;
use std::sync::Arc;
use tokio::{
    sync::{mpsc, oneshot},
    task::spawn_blocking,
};

#[rustfmt::skip]
// ┌──────────────┐     ┌────────────┐ 1  n ┌───────────────┐
// │ DocumentCore │────▶│ DocManager │─────▶│ OpenDocHandle │
// └──────────────┘     └────────────┘      └───────────────┘
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
    fn receive_data(&self, client_data: WsClientData) {
        let (ret, rx) = oneshot::channel();
        let sender = self.ws_sender.clone();
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

#[rustfmt::skip]
//                                              EditDocActor
//                                             ┌────────────────────────────────────┐
//                                             │  ServerDocEditor                   │
//                                             │  ┌──────────────────────────────┐  │
// ┌────────────┐ 1  n ┌───────────────┐       │  │ ┌──────────┐    ┌──────────┐ │  │
// │ DocManager │─────▶│ OpenDocHandle │──────▶│  │ │ Document │    │  Users   │ │  │
// └────────────┘      └───────────────┘       │  │ └──────────┘    └──────────┘ │  │
//                                             │  └──────────────────────────────┘  │
//                                             │                                    │
//                                             └────────────────────────────────────┘
pub struct DocManager {
    open_doc_map: DashMap<String, Arc<OpenDocHandle>>,
}

impl std::default::Default for DocManager {
    fn default() -> Self {
        Self {
            open_doc_map: DashMap::new(),
        }
    }
}

impl DocManager {
    pub fn new() -> Self { DocManager::default() }

    pub async fn get(&self, doc_id: &str, pg_pool: Data<PgPool>) -> Result<Option<Arc<OpenDocHandle>>, ServerError> {
        match self.open_doc_map.get(doc_id) {
            None => {
                let params = DocIdentifier {
                    doc_id: doc_id.to_string(),
                    ..Default::default()
                };
                let doc = read_doc(pg_pool.get_ref(), params).await?;
                let handle = spawn_blocking(|| OpenDocHandle::new(doc, pg_pool))
                    .await
                    .map_err(internal_error)?;
                let handle = Arc::new(handle?);
                self.open_doc_map.insert(doc_id.to_string(), handle.clone());
                Ok(Some(handle))
            },
            Some(ctx) => Ok(Some(ctx.clone())),
        }
    }
}

pub struct OpenDocHandle {
    pub sender: mpsc::Sender<EditMsg>,
}

impl OpenDocHandle {
    pub fn new(doc: Doc, pg_pool: Data<PgPool>) -> Result<Self, ServerError> {
        let (sender, receiver) = mpsc::channel(100);
        let actor = EditDocActor::new(receiver, doc, pg_pool)?;
        tokio::task::spawn(actor.run());
        Ok(Self { sender })
    }

    pub async fn add_user(&self, user: Arc<WsUser>, rev_id: i64, socket: Socket) -> Result<(), ServerError> {
        let (ret, rx) = oneshot::channel();
        let msg = EditMsg::NewDocUser {
            user,
            socket,
            rev_id,
            ret,
        };
        let _ = self.send(msg, rx).await?;
        Ok(())
    }

    pub async fn apply_revision(
        &self,
        user: Arc<WsUser>,
        socket: Socket,
        revision: Revision,
    ) -> Result<(), ServerError> {
        let (ret, rx) = oneshot::channel();
        let msg = EditMsg::Revision {
            user,
            socket,
            revision,
            ret,
        };
        let _ = self.send(msg, rx).await?;
        Ok(())
    }

    pub async fn document_json(&self) -> DocResult<String> {
        let (ret, rx) = oneshot::channel();
        let msg = EditMsg::DocumentJson { ret };
        self.send(msg, rx).await?
    }

    pub async fn rev_id(&self) -> DocResult<i64> {
        let (ret, rx) = oneshot::channel();
        let msg = EditMsg::DocumentRevId { ret };
        self.send(msg, rx).await?
    }

    pub(crate) async fn send<T>(&self, msg: EditMsg, rx: oneshot::Receiver<T>) -> DocResult<T> {
        let _ = self.sender.send(msg).await.map_err(internal_error)?;
        let result = rx.await?;
        Ok(result)
    }
}
