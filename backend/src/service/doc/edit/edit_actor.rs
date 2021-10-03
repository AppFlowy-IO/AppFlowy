use crate::service::{
    doc::edit::ServerEditDoc,
    ws::{entities::Socket, WsUser},
};
use actix_web::web::Data;
use async_stream::stream;
use flowy_document::protobuf::{Doc, Revision};
use flowy_net::errors::{internal_error, Result as DocResult, ServerError};
use futures::stream::StreamExt;
use sqlx::PgPool;
use std::sync::Arc;
use tokio::{
    sync::{mpsc, oneshot},
    task::spawn_blocking,
};

#[derive(Clone)]
pub struct EditUser {
    user: Arc<WsUser>,
    pub(crate) socket: Socket,
}

impl EditUser {
    pub fn id(&self) -> String { self.user.id().to_string() }
}

#[derive(Debug)]
pub enum EditMsg {
    Revision {
        user: Arc<WsUser>,
        socket: Socket,
        revision: Revision,
        ret: oneshot::Sender<DocResult<()>>,
    },
    DocumentJson {
        ret: oneshot::Sender<DocResult<String>>,
    },
    NewDocUser {
        user: Arc<WsUser>,
        socket: Socket,
        rev_id: i64,
        ret: oneshot::Sender<DocResult<()>>,
    },
}

pub struct EditDocActor {
    receiver: Option<mpsc::Receiver<EditMsg>>,
    edit_doc: Arc<ServerEditDoc>,
    pg_pool: Data<PgPool>,
}

impl EditDocActor {
    pub fn new(receiver: mpsc::Receiver<EditMsg>, doc: Doc, pg_pool: Data<PgPool>) -> Result<Self, ServerError> {
        let edit_doc = Arc::new(ServerEditDoc::new(doc)?);
        Ok(Self {
            receiver: Some(receiver),
            edit_doc,
            pg_pool,
        })
    }

    pub async fn run(mut self) {
        let mut receiver = self
            .receiver
            .take()
            .expect("DocActor's receiver should only take one time");

        let stream = stream! {
            loop {
                match receiver.recv().await {
                    Some(msg) => yield msg,
                    None => break,
                }
            }
        };
        stream.for_each(|msg| self.handle_message(msg)).await;
    }

    async fn handle_message(&self, msg: EditMsg) {
        match msg {
            EditMsg::Revision {
                user,
                socket,
                revision,
                ret,
            } => {
                let user = EditUser {
                    user: user.clone(),
                    socket: socket.clone(),
                };
                let _ = ret.send(self.edit_doc.apply_revision(user, revision, self.pg_pool.clone()).await);
            },
            EditMsg::DocumentJson { ret } => {
                let edit_context = self.edit_doc.clone();
                let json = spawn_blocking(move || edit_context.document_json())
                    .await
                    .map_err(internal_error);
                let _ = ret.send(json);
            },
            EditMsg::NewDocUser {
                user,
                socket,
                rev_id,
                ret,
            } => {
                let user = EditUser {
                    user: user.clone(),
                    socket: socket.clone(),
                };
                let _ = ret.send(self.edit_doc.new_connection(user, rev_id, self.pg_pool.clone()).await);
            },
        }
    }
}
