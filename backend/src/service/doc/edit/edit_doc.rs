use crate::service::{
    doc::edit::{
        actor::{EditDocActor, EditMsg},
        EditDocContext,
    },
    ws::{entities::Socket, WsUser},
};
use flowy_document::protobuf::{Doc, Revision};
use flowy_net::errors::{internal_error, Result as DocResult, ServerError};
use std::sync::Arc;
use tokio::sync::{mpsc, oneshot};
pub struct EditDoc {
    sender: mpsc::Sender<EditMsg>,
}

impl EditDoc {
    pub fn new(doc: Doc) -> Result<Self, ServerError> {
        let (sender, receiver) = mpsc::channel(100);
        let edit_context = Arc::new(EditDocContext::new(doc)?);

        let actor = EditDocActor::new(receiver, edit_context);
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
