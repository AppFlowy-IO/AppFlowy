use crate::{
    services::{
        doc::editor::ServerDocUser,
        util::{md5, parse_from_bytes},
    },
    web_socket::WsClientData,
};
use actix_rt::task::spawn_blocking;
use actix_web::web::Data;
use async_stream::stream;
use backend_service::errors::{internal_error, Result, ServerError};
use flowy_collaboration::{
    core::sync::{RevisionUser, ServerDocManager, SyncResponse},
    entities::ws::DocumentWSDataBuilder,
    protobuf::{DocumentWSData, DocumentWSDataType},
};

use flowy_collaboration::protobuf::NewDocumentUser;
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

    async fn handle_client_data(&self, client_data: WsClientData, pg_pool: Data<PgPool>) -> Result<()> {
        let WsClientData { user, socket, data } = client_data;
        let document_data = spawn_blocking(move || {
            let document_data: DocumentWSData = parse_from_bytes(&data)?;
            Result::Ok(document_data)
        })
        .await
        .map_err(internal_error)??;

        tracing::debug!(
            "[HTTP_SERVER_WS]: receive client data: {}:{}, {:?}",
            document_data.doc_id,
            document_data.id,
            document_data.ty
        );

        let user = Arc::new(ServerDocUser { user, socket, pg_pool });
        let result = match &document_data.ty {
            DocumentWSDataType::Ack => Ok(()),
            DocumentWSDataType::PushRev => self.handle_pushed_rev(user, document_data.data).await,
            DocumentWSDataType::PullRev => Ok(()),
            DocumentWSDataType::UserConnect => self.handle_user_connect(user, document_data).await,
        };
        match result {
            Ok(_) => {},
            Err(e) => {
                tracing::error!("[HTTP_SERVER_WS]: process client data error {:?}", e);
            },
        }

        Ok(())
    }

    async fn handle_user_connect(&self, user: Arc<ServerDocUser>, document_data: DocumentWSData) -> Result<()> {
        let mut new_user = spawn_blocking(move || parse_from_bytes::<NewDocumentUser>(&document_data.data))
            .await
            .map_err(internal_error)??;

        let revision_pb = spawn_blocking(move || parse_from_bytes::<Revision>(&new_user.take_revision_data()))
            .await
            .map_err(internal_error)??;
        let _ = self.handle_revision(user, revision_pb).await?;
        Ok(())
    }

    async fn handle_pushed_rev(&self, user: Arc<ServerDocUser>, data: Vec<u8>) -> Result<()> {
        let revision_pb = spawn_blocking(move || {
            let revision: Revision = parse_from_bytes(&data)?;
            // let _ = verify_md5(&revision)?;
            Result::Ok(revision)
        })
        .await
        .map_err(internal_error)??;
        self.handle_revision(user, revision_pb).await
    }

    async fn handle_revision(&self, user: Arc<ServerDocUser>, mut revision: Revision) -> Result<()> {
        let revision: lib_ot::revision::Revision = (&mut revision).try_into().map_err(internal_error)?;
        // Create the doc if it doesn't exist
        let handler = match self.doc_manager.get(&revision.doc_id).await {
            None => self
                .doc_manager
                .create_doc(revision.clone())
                .await
                .map_err(internal_error)?,
            Some(handler) => handler,
        };

        handler.apply_revision(user, revision).await.map_err(internal_error)?;
        Ok(())
    }
}

#[allow(dead_code)]
fn verify_md5(revision: &Revision) -> Result<()> {
    if md5(&revision.delta_data) != revision.md5 {
        return Err(ServerError::internal().context("Revision md5 not match"));
    }
    Ok(())
}
