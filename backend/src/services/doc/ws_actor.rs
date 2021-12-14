use crate::{
    services::{
        doc::editor::ServerDocUser,
        util::{md5, parse_from_bytes},
    },
    web_socket::{entities::Socket, WsClientData, WsUser},
};
use actix_rt::task::spawn_blocking;
use actix_web::web::Data;
use async_stream::stream;
use backend_service::errors::{internal_error, Result, ServerError};
use flowy_collaboration::{
    core::sync::ServerDocManager,
    protobuf::{WsDataType, WsDocumentData},
};
use futures::stream::StreamExt;
use lib_ot::protobuf::Revision;
use sqlx::PgPool;
use std::{convert::TryInto, sync::Arc};
use tokio::sync::{mpsc, oneshot};

pub enum DocWsMsg {
    ClientData {
        client_data: WsClientData,
        pool: Data<PgPool>,
        ret: oneshot::Sender<Result<()>>,
    },
}

pub struct DocWsActor {
    receiver: Option<mpsc::Receiver<DocWsMsg>>,
    doc_manager: Arc<ServerDocManager>,
}

impl DocWsActor {
    pub fn new(receiver: mpsc::Receiver<DocWsMsg>, manager: Arc<ServerDocManager>) -> Self {
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

    async fn handle_client_data(&self, client_data: WsClientData, pool: Data<PgPool>) -> Result<()> {
        let WsClientData { user, socket, data } = client_data;
        let document_data = spawn_blocking(move || {
            let document_data: WsDocumentData = parse_from_bytes(&data)?;
            Result::Ok(document_data)
        })
        .await
        .map_err(internal_error)??;

        let data = document_data.data;

        match document_data.ty {
            WsDataType::Acked => Ok(()),
            WsDataType::PushRev => self.apply_pushed_rev(user, socket, data, pool).await,
            WsDataType::PullRev => Ok(()),
            WsDataType::Conflict => Ok(()),
        }
    }

    async fn apply_pushed_rev(
        &self,
        user: Arc<WsUser>,
        socket: Socket,
        data: Vec<u8>,
        pg_pool: Data<PgPool>,
    ) -> Result<()> {
        let mut revision_pb = spawn_blocking(move || {
            let revision: Revision = parse_from_bytes(&data)?;
            let _ = verify_md5(&revision)?;
            Result::Ok(revision)
        })
        .await
        .map_err(internal_error)??;
        let revision: lib_ot::revision::Revision = (&mut revision_pb).try_into().map_err(internal_error)?;
        // Create the doc if it doesn't exist
        let handler = match self.doc_manager.get(&revision.doc_id).await {
            None => self
                .doc_manager
                .create_doc(revision.clone())
                .await
                .map_err(internal_error)?,
            Some(handler) => handler,
        };

        let user = Arc::new(ServerDocUser { user, socket, pg_pool });
        handler.apply_revision(user, revision).await.map_err(internal_error)?;
        Ok(())
    }
}

fn verify_md5(revision: &Revision) -> Result<()> {
    if md5(&revision.delta_data) != revision.md5 {
        return Err(ServerError::internal().context("Revision md5 not match"));
    }
    Ok(())
}
