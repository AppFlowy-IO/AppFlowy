use crate::service::{
    doc::edit::{
        edit_actor::{EditDocActor, EditMsg},
        ServerEditDoc,
    },
    ws::{entities::Socket, WsUser},
};
use actix_web::web::Data;
use flowy_document::protobuf::{Doc, Revision};
use flowy_net::errors::{internal_error, Result as DocResult, ServerError};
use sqlx::PgPool;
use std::sync::Arc;
use tokio::sync::{mpsc, oneshot};

pub struct DocHandle {
    sender: mpsc::Sender<EditMsg>,
}

impl DocHandle {
    pub fn new(doc: Doc, pg_pool: Data<PgPool>) -> Result<Self, ServerError> {
        let (sender, receiver) = mpsc::channel(100);
        let actor = EditDocActor::new(receiver, doc, pg_pool)?;
        tokio::task::spawn(actor.run());

        Ok(Self { sender })
    }

    #[tracing::instrument(level = "debug", skip(self, user, socket, revision))]
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

    async fn send<T>(&self, msg: EditMsg, rx: oneshot::Receiver<T>) -> DocResult<T> {
        let _ = self.sender.send(msg).await.map_err(internal_error)?;
        let result = rx.await?;
        Ok(result)
    }
}
