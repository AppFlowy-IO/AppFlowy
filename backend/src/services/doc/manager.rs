use crate::{
    services::doc::{
        read_doc,
        update_doc,
        ws_actor::{DocWsActor, DocWsMsg},
    },
    web_socket::{WsBizHandler, WsClientData},
};
use actix_web::web::Data;

use crate::services::doc::create_doc;
use backend_service::errors::ServerError;
use flowy_collaboration::{
    core::sync::{ServerDocManager, ServerDocPersistence},
    entities::doc::Doc,
    errors::CollaborateError,
    protobuf::{CreateDocParams, DocIdentifier, UpdateDocParams},
};
use lib_infra::future::FutureResultSend;
use lib_ot::{revision::Revision, rich_text::RichTextDelta};
use sqlx::PgPool;
use std::{convert::TryInto, sync::Arc};
use tokio::sync::{mpsc, oneshot};

pub struct DocumentCore {
    pub manager: Arc<ServerDocManager>,
    ws_sender: mpsc::Sender<DocWsMsg>,
    pg_pool: Data<PgPool>,
}

impl DocumentCore {
    pub fn new(pg_pool: Data<PgPool>) -> Self {
        let manager = Arc::new(ServerDocManager::new(Arc::new(DocPersistenceImpl(pg_pool.clone()))));
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

struct DocPersistenceImpl(Data<PgPool>);
impl ServerDocPersistence for DocPersistenceImpl {
    fn update_doc(&self, doc_id: &str, rev_id: i64, delta: RichTextDelta) -> FutureResultSend<(), CollaborateError> {
        let pg_pool = self.0.clone();
        let mut params = UpdateDocParams::new();
        let doc_json = delta.to_json();
        params.set_doc_id(doc_id.to_string());
        params.set_data(doc_json);
        params.set_rev_id(rev_id);

        FutureResultSend::new(async move {
            let _ = update_doc(pg_pool.get_ref(), params)
                .await
                .map_err(server_error_to_collaborate_error)?;
            Ok(())
        })
    }

    fn read_doc(&self, doc_id: &str) -> FutureResultSend<Doc, CollaborateError> {
        let params = DocIdentifier {
            doc_id: doc_id.to_string(),
            ..Default::default()
        };
        let pg_pool = self.0.clone();
        FutureResultSend::new(async move {
            let mut pb_doc = read_doc(pg_pool.get_ref(), params)
                .await
                .map_err(server_error_to_collaborate_error)?;
            let doc = (&mut pb_doc)
                .try_into()
                .map_err(|e| CollaborateError::internal().context(e))?;
            Ok(doc)
        })
    }

    fn create_doc(&self, revision: Revision) -> FutureResultSend<Doc, CollaborateError> {
        let pg_pool = self.0.clone();
        FutureResultSend::new(async move {
            let delta = RichTextDelta::from_bytes(&revision.delta_data)?;
            let doc_json = delta.to_json();

            let params = CreateDocParams {
                id: revision.doc_id.clone(),
                data: doc_json.clone(),
                unknown_fields: Default::default(),
                cached_size: Default::default(),
            };

            let _ = create_doc(pg_pool.get_ref(), params)
                .await
                .map_err(server_error_to_collaborate_error)?;
            let doc: Doc = revision.try_into()?;
            Ok(doc)
        })
    }
}

fn server_error_to_collaborate_error(error: ServerError) -> CollaborateError {
    if error.is_record_not_found() {
        CollaborateError::record_not_found()
    } else {
        CollaborateError::internal().context(error)
    }
}
