use crate::service::{
    doc::doc::DocManager,
    util::{md5, parse_from_bytes},
    ws::{entities::Socket, WsClientData, WsUser},
};
use actix_rt::task::spawn_blocking;
use actix_web::web::Data;
use async_stream::stream;
use flowy_document::protobuf::{Revision, WsDataType, WsDocumentData};
use flowy_net::errors::{internal_error, Result as DocResult, ServerError};
use futures::stream::StreamExt;
use sqlx::PgPool;
use std::sync::Arc;
use tokio::sync::{mpsc, oneshot};

pub enum DocWsMsg {
    ClientData {
        client_data: WsClientData,
        pool: Data<PgPool>,
        ret: oneshot::Sender<DocResult<()>>,
    },
}

pub struct DocWsActor {
    receiver: Option<mpsc::Receiver<DocWsMsg>>,
    doc_manager: Arc<DocManager>,
}

impl DocWsActor {
    pub fn new(receiver: mpsc::Receiver<DocWsMsg>, manager: Arc<DocManager>) -> Self {
        Self {
            receiver: Some(receiver),
            doc_manager: manager,
        }
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

    async fn handle_message(&self, msg: DocWsMsg) {
        match msg {
            DocWsMsg::ClientData { client_data, pool, ret } => {
                let _ = ret.send(self.handle_client_data(client_data, pool).await);
            },
        }
    }

    async fn handle_client_data(&self, client_data: WsClientData, pool: Data<PgPool>) -> DocResult<()> {
        let WsClientData { user, socket, data } = client_data;
        let document_data = spawn_blocking(move || {
            let document_data: WsDocumentData = parse_from_bytes(&data)?;
            DocResult::Ok(document_data)
        })
        .await
        .map_err(internal_error)??;

        match document_data.ty {
            WsDataType::Acked => Ok(()),
            WsDataType::PushRev => self.handle_push_rev(user, socket, document_data.data, pool).await,
            WsDataType::NewConnection => {
                // TODO: send notifications to other users who visited the doc
                Ok(())
            },
            WsDataType::PullRev => Ok(()),
            WsDataType::Conflict => Ok(()),
        }
    }

    async fn handle_push_rev(
        &self,
        user: Arc<WsUser>,
        socket: Socket,
        revision_data: Vec<u8>,
        pool: Data<PgPool>,
    ) -> DocResult<()> {
        let revision = spawn_blocking(move || {
            let revision: Revision = parse_from_bytes(&revision_data)?;
            let _ = verify_md5(&revision)?;
            DocResult::Ok(revision)
        })
        .await
        .map_err(internal_error)??;

        match self.doc_manager.get(&revision.doc_id, pool).await? {
            Some(edit_doc) => {
                edit_doc.apply_revision(user, socket, revision).await?;
                Ok(())
            },
            None => {
                log::error!("Document with id: {} not exist", &revision.doc_id);
                Ok(())
            },
        }
    }
}

fn verify_md5(revision: &Revision) -> DocResult<()> {
    if md5(&revision.delta_data) != revision.md5 {
        return Err(ServerError::internal().context("Revision md5 not match"));
    }
    Ok(())
}
