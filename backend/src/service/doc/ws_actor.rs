use crate::service::{doc::doc::DocManager, util::parse_from_bytes, ws::WsClientData};
use actix_rt::task::spawn_blocking;
use actix_web::web::Data;
use async_stream::stream;
use flowy_document::protobuf::{Revision, WsDataType, WsDocumentData};
use flowy_net::errors::{internal_error, Result as DocResult};
use futures::stream::StreamExt;
use sqlx::PgPool;
use std::sync::Arc;
use tokio::sync::{mpsc, oneshot};

pub enum DocWsMsg {
    ClientData {
        data: WsClientData,
        pool: Data<PgPool>,
        ret: oneshot::Sender<DocResult<()>>,
    },
}

pub struct DocWsMsgActor {
    receiver: Option<mpsc::Receiver<DocWsMsg>>,
    doc_manager: Arc<DocManager>,
}

impl DocWsMsgActor {
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
            DocWsMsg::ClientData { data, pool, ret } => {
                ret.send(self.handle_client_data(data, pool).await);
            },
        }
    }

    async fn handle_client_data(&self, data: WsClientData, pool: Data<PgPool>) -> DocResult<()> {
        let bytes = data.data.clone();
        let document_data = spawn_blocking(move || {
            let document_data: WsDocumentData = parse_from_bytes(&bytes)?;
            DocResult::Ok(document_data)
        })
        .await
        .map_err(internal_error)??;

        match document_data.ty {
            WsDataType::Acked => {},
            WsDataType::PushRev => self.handle_push_rev(data, document_data.data, pool).await?,
            WsDataType::PullRev => {},
            WsDataType::Conflict => {},
        }
        Ok(())
    }

    async fn handle_push_rev(
        &self,
        client_data: WsClientData,
        revision_data: Vec<u8>,
        pool: Data<PgPool>,
    ) -> DocResult<()> {
        let revision = spawn_blocking(move || {
            let revision: Revision = parse_from_bytes(&revision_data)?;
            DocResult::Ok(revision)
        })
        .await
        .map_err(internal_error)??;

        match self.doc_manager.get(&revision.doc_id, pool).await? {
            Some(ctx) => {
                ctx.apply_revision(client_data, revision).await;
                Ok(())
            },
            None => {
                //
                Ok(())
            },
        }
    }
}
