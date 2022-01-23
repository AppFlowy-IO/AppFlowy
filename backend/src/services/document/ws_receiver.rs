use crate::{
    context::{DocumentRevisionKV, FlowyPersistence},
    services::{
        document::{
            persistence::{create_document, read_document},
            ws_actor::{DocumentWSActorMessage, DocumentWebSocketActor},
        },
        kv::revision_kv::revisions_to_key_value_items,
        web_socket::{WSClientData, WebSocketReceiver},
    },
};
use backend_service::errors::ServerError;
use flowy_collaboration::{
    entities::document_info::DocumentInfo,
    errors::CollaborateError,
    protobuf::{
        CreateDocParams as CreateDocParamsPB,
        DocumentId,
        RepeatedRevision as RepeatedRevisionPB,
        Revision as RevisionPB,
    },
    server_document::{DocumentCloudPersistence, ServerDocumentManager},
    util::make_document_info_from_revisions_pb,
};
use lib_infra::future::BoxResultFuture;
use std::{
    convert::TryInto,
    fmt::{Debug, Formatter},
    sync::Arc,
};
use tokio::sync::{mpsc, oneshot};

pub fn make_document_ws_receiver(
    persistence: Arc<FlowyPersistence>,
    document_manager: Arc<ServerDocumentManager>,
) -> Arc<DocumentWebSocketReceiver> {
    let (actor_msg_sender, rx) = tokio::sync::mpsc::channel(1000);
    let actor = DocumentWebSocketActor::new(rx, document_manager);
    tokio::task::spawn(actor.run());

    Arc::new(DocumentWebSocketReceiver::new(persistence, actor_msg_sender))
}

pub struct DocumentWebSocketReceiver {
    actor_msg_sender: mpsc::Sender<DocumentWSActorMessage>,
    persistence: Arc<FlowyPersistence>,
}

impl DocumentWebSocketReceiver {
    pub fn new(persistence: Arc<FlowyPersistence>, actor_msg_sender: mpsc::Sender<DocumentWSActorMessage>) -> Self {
        Self {
            actor_msg_sender,
            persistence,
        }
    }
}

impl WebSocketReceiver for DocumentWebSocketReceiver {
    fn receive(&self, data: WSClientData) {
        let (ret, rx) = oneshot::channel();
        let actor_msg_sender = self.actor_msg_sender.clone();
        let persistence = self.persistence.clone();

        actix_rt::spawn(async move {
            let msg = DocumentWSActorMessage::ClientData {
                client_data: data,
                persistence,
                ret,
            };

            match actor_msg_sender.send(msg).await {
                Ok(_) => {},
                Err(e) => log::error!("[DocumentWebSocketReceiver]: send message to actor failed: {}", e),
            }
            match rx.await {
                Ok(_) => {},
                Err(e) => log::error!("[DocumentWebSocketReceiver]: message ret failed {:?}", e),
            };
        });
    }
}

pub struct HttpDocumentCloudPersistence(pub Arc<DocumentRevisionKV>);
impl Debug for HttpDocumentCloudPersistence {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result { f.write_str("HttpDocumentCloudPersistence") }
}

impl DocumentCloudPersistence for HttpDocumentCloudPersistence {
    fn read_document(&self, doc_id: &str) -> BoxResultFuture<DocumentInfo, CollaborateError> {
        let params = DocumentId {
            doc_id: doc_id.to_string(),
            ..Default::default()
        };
        let document_store = self.0.clone();
        Box::pin(async move {
            let mut pb_doc = read_document(&document_store, params)
                .await
                .map_err(|e| e.to_collaborate_error())?;
            let doc = (&mut pb_doc)
                .try_into()
                .map_err(|e| CollaborateError::internal().context(e))?;
            Ok(doc)
        })
    }

    fn create_document(
        &self,
        doc_id: &str,
        repeated_revision: RepeatedRevisionPB,
    ) -> BoxResultFuture<Option<DocumentInfo>, CollaborateError> {
        let document_store = self.0.clone();
        let doc_id = doc_id.to_owned();
        Box::pin(async move {
            let document_info = make_document_info_from_revisions_pb(&doc_id, repeated_revision.clone())?;
            let doc_id = doc_id.to_owned();
            let mut params = CreateDocParamsPB::new();
            params.set_id(doc_id);
            params.set_revisions(repeated_revision);
            let _ = create_document(&document_store, params)
                .await
                .map_err(|e| e.to_collaborate_error())?;
            Ok(document_info)
        })
    }

    fn read_document_revisions(
        &self,
        doc_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> BoxResultFuture<Vec<RevisionPB>, CollaborateError> {
        let document_store = self.0.clone();
        let doc_id = doc_id.to_owned();
        let f = || async move {
            let mut repeated_revision = document_store.get_revisions(&doc_id, rev_ids).await?;
            Ok::<Vec<RevisionPB>, ServerError>(repeated_revision.take_items().into())
        };

        Box::pin(async move { f().await.map_err(|e| e.to_collaborate_error()) })
    }

    fn save_document_revisions(
        &self,
        mut repeated_revision: RepeatedRevisionPB,
    ) -> BoxResultFuture<(), CollaborateError> {
        let document_store = self.0.clone();
        let f = || async move {
            let revisions = repeated_revision.take_items().into();
            let _ = document_store.set_revision(revisions).await?;
            Ok::<(), ServerError>(())
        };

        Box::pin(async move { f().await.map_err(|e| e.to_collaborate_error()) })
    }

    fn reset_document(
        &self,
        doc_id: &str,
        mut repeated_revision: RepeatedRevisionPB,
    ) -> BoxResultFuture<(), CollaborateError> {
        let document_store = self.0.clone();
        let doc_id = doc_id.to_owned();
        let f = || async move {
            document_store
                .transaction(|mut transaction| {
                    Box::pin(async move {
                        let _ = transaction.batch_delete_key_start_with(&doc_id).await?;
                        let items = revisions_to_key_value_items(repeated_revision.take_items().into())?;
                        let _ = transaction.batch_set(items).await?;
                        Ok(())
                    })
                })
                .await
        };
        Box::pin(async move { f().await.map_err(|e| e.to_collaborate_error()) })
    }
}
