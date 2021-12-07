use crate::{
    services::{
        doc::manager::{DocManager, DocOpenHandle},
        util::{md5, parse_from_bytes},
    },
    web_socket::{entities::Socket, WsClientData, WsUser},
};
use actix_rt::task::spawn_blocking;
use actix_web::web::Data;
use async_stream::stream;
use backend_service::errors::{internal_error, Result as DocResult, ServerError};
use flowy_document_infra::protobuf::{NewDocUser, WsDataType, WsDocumentData};
use futures::stream::StreamExt;
use lib_ot::protobuf::Revision;
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

        let data = document_data.data;

        match document_data.ty {
            WsDataType::Acked => Ok(()),
            WsDataType::PushRev => self.apply_pushed_rev(user, socket, data, pool).await,
            WsDataType::NewDocUser => self.add_doc_user(user, socket, data, pool).await,
            WsDataType::PullRev => Ok(()),
            WsDataType::Conflict => Ok(()),
        }
    }

    async fn add_doc_user(
        &self,
        user: Arc<WsUser>,
        socket: Socket,
        data: Vec<u8>,
        pool: Data<PgPool>,
    ) -> DocResult<()> {
        let doc_user = spawn_blocking(move || {
            let user: NewDocUser = parse_from_bytes(&data)?;
            DocResult::Ok(user)
        })
        .await
        .map_err(internal_error)??;
        if let Some(handle) = self.find_doc_handle(&doc_user.doc_id, pool).await {
            handle.add_user(user, doc_user.rev_id, socket).await?;
        }
        Ok(())
    }

    async fn apply_pushed_rev(
        &self,
        user: Arc<WsUser>,
        socket: Socket,
        data: Vec<u8>,
        pool: Data<PgPool>,
    ) -> DocResult<()> {
        let revision = spawn_blocking(move || {
            let revision: Revision = parse_from_bytes(&data)?;
            let _ = verify_md5(&revision)?;
            DocResult::Ok(revision)
        })
        .await
        .map_err(internal_error)??;
        if let Some(handle) = self.find_doc_handle(&revision.doc_id, pool).await {
            handle.apply_revision(user, socket, revision).await?;
        }
        Ok(())
    }

    async fn find_doc_handle(&self, doc_id: &str, pool: Data<PgPool>) -> Option<Arc<DocOpenHandle>> {
        match self.doc_manager.get(doc_id, pool).await {
            Ok(Some(edit_doc)) => Some(edit_doc),
            Ok(None) => {
                log::error!("Document with id: {} not exist", doc_id);
                None
            },
            Err(e) => {
                log::error!("Get doc handle failed: {:?}", e);
                None
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
