<<<<<<< HEAD
<<<<<<< HEAD
use crate::services::{
    document::{
        persistence::{create_document, read_document},
        ws_actor::{DocumentWebSocketActor, WSActorMessage},
    },
    web_socket::{WSClientData, WebSocketReceiver},
};

use crate::context::FlowyPersistence;
use backend_service::errors::ServerError;
use flowy_collaboration::{
    entities::{
        doc::{CreateDocParams, DocumentInfo},
        revision::{RepeatedRevision, Revision},
    },
    errors::CollaborateError,
    protobuf::DocumentId,
    sync::{DocumentPersistence, ServerDocumentManager},
=======
=======
>>>>>>> upstream/main
use crate::{
    context::FlowyPersistence,
    services::{
        document::{
            persistence::{create_document, read_document, revisions_to_key_value_items},
            ws_actor::{DocumentWebSocketActor, WSActorMessage},
        },
        web_socket::{WSClientData, WebSocketReceiver},
    },
};
use backend_service::errors::ServerError;
use flowy_collaboration::{
    entities::doc::DocumentInfo,
    errors::CollaborateError,
    protobuf::{
        CreateDocParams as CreateDocParamsPB,
        DocumentId,
        RepeatedRevision as RepeatedRevisionPB,
        Revision as RevisionPB,
    },
    sync::{DocumentPersistence, ServerDocumentManager},
    util::repeated_revision_from_repeated_revision_pb,
<<<<<<< HEAD
>>>>>>> upstream/main
=======
>>>>>>> upstream/main
};
use lib_infra::future::BoxResultFuture;
use std::{
    convert::TryInto,
    fmt::{Debug, Formatter},
    sync::Arc,
};
use tokio::sync::{mpsc, oneshot};

<<<<<<< HEAD
<<<<<<< HEAD
pub fn make_document_ws_receiver(persistence: Arc<FlowyPersistence>) -> Arc<DocumentWebSocketReceiver> {
    let document_persistence = Arc::new(DocumentPersistenceImpl(persistence.clone()));
    let document_manager = Arc::new(ServerDocumentManager::new(document_persistence));

=======
=======
>>>>>>> upstream/main
pub fn make_document_ws_receiver(
    persistence: Arc<FlowyPersistence>,
    document_manager: Arc<ServerDocumentManager>,
) -> Arc<DocumentWebSocketReceiver> {
<<<<<<< HEAD
>>>>>>> upstream/main
=======
>>>>>>> upstream/main
    let (ws_sender, rx) = tokio::sync::mpsc::channel(100);
    let actor = DocumentWebSocketActor::new(rx, document_manager);
    tokio::task::spawn(actor.run());

    Arc::new(DocumentWebSocketReceiver::new(persistence, ws_sender))
}

pub struct DocumentWebSocketReceiver {
    ws_sender: mpsc::Sender<WSActorMessage>,
    persistence: Arc<FlowyPersistence>,
}

impl DocumentWebSocketReceiver {
    pub fn new(persistence: Arc<FlowyPersistence>, ws_sender: mpsc::Sender<WSActorMessage>) -> Self {
        Self { ws_sender, persistence }
    }
}

impl WebSocketReceiver for DocumentWebSocketReceiver {
    fn receive(&self, data: WSClientData) {
        let (ret, rx) = oneshot::channel();
        let sender = self.ws_sender.clone();
        let persistence = self.persistence.clone();

        actix_rt::spawn(async move {
            let msg = WSActorMessage::ClientData {
                client_data: data,
                persistence,
                ret,
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

<<<<<<< HEAD
<<<<<<< HEAD
struct DocumentPersistenceImpl(Arc<FlowyPersistence>);
=======
pub struct DocumentPersistenceImpl(pub Arc<FlowyPersistence>);
>>>>>>> upstream/main
=======
pub struct DocumentPersistenceImpl(pub Arc<FlowyPersistence>);
>>>>>>> upstream/main
impl Debug for DocumentPersistenceImpl {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result { f.write_str("DocumentPersistenceImpl") }
}

impl DocumentPersistence for DocumentPersistenceImpl {
    fn read_doc(&self, doc_id: &str) -> BoxResultFuture<DocumentInfo, CollaborateError> {
        let params = DocumentId {
            doc_id: doc_id.to_string(),
            ..Default::default()
        };
<<<<<<< HEAD
<<<<<<< HEAD
        let persistence = self.0.kv_store();
        Box::pin(async move {
            let mut pb_doc = read_document(&persistence, params)
=======
        let kv_store = self.0.kv_store();
        Box::pin(async move {
            let mut pb_doc = read_document(&kv_store, params)
>>>>>>> upstream/main
=======
        let kv_store = self.0.kv_store();
        Box::pin(async move {
            let mut pb_doc = read_document(&kv_store, params)
>>>>>>> upstream/main
                .await
                .map_err(server_error_to_collaborate_error)?;
            let doc = (&mut pb_doc)
                .try_into()
                .map_err(|e| CollaborateError::internal().context(e))?;
            Ok(doc)
        })
    }

<<<<<<< HEAD
<<<<<<< HEAD
    fn create_doc(&self, doc_id: &str, revisions: Vec<Revision>) -> BoxResultFuture<DocumentInfo, CollaborateError> {
        let kv_store = self.0.kv_store();
        let doc_id = doc_id.to_owned();
        Box::pin(async move {
            let doc = DocumentInfo::from_revisions(&doc_id, revisions.clone())?;
            let doc_id = doc_id.to_owned();
            let revisions = RepeatedRevision::new(revisions);
            let params = CreateDocParams { id: doc_id, revisions };
            let pb_params: flowy_collaboration::protobuf::CreateDocParams = params.try_into().unwrap();
            let _ = create_document(&kv_store, pb_params)
=======
=======
>>>>>>> upstream/main
    fn create_doc(
        &self,
        doc_id: &str,
        repeated_revision: RepeatedRevisionPB,
    ) -> BoxResultFuture<DocumentInfo, CollaborateError> {
        let kv_store = self.0.kv_store();
        let doc_id = doc_id.to_owned();
        Box::pin(async move {
            let revisions = repeated_revision_from_repeated_revision_pb(repeated_revision.clone())?.into_inner();
            let doc = DocumentInfo::from_revisions(&doc_id, revisions)?;
            let doc_id = doc_id.to_owned();
            let mut params = CreateDocParamsPB::new();
            params.set_id(doc_id);
            params.set_revisions(repeated_revision);
            let _ = create_document(&kv_store, params)
<<<<<<< HEAD
>>>>>>> upstream/main
=======
>>>>>>> upstream/main
                .await
                .map_err(server_error_to_collaborate_error)?;
            Ok(doc)
        })
    }

<<<<<<< HEAD
<<<<<<< HEAD
    fn get_revisions(&self, doc_id: &str, rev_ids: Vec<i64>) -> BoxResultFuture<Vec<Revision>, CollaborateError> {
        let kv_store = self.0.kv_store();
        let doc_id = doc_id.to_owned();
        let f = || async move {
            let mut pb = kv_store.batch_get_revisions(&doc_id, rev_ids).await?;
            let repeated_revision: RepeatedRevision = (&mut pb).try_into()?;
            let revisions = repeated_revision.into_inner();
            Ok(revisions)
=======
=======
>>>>>>> upstream/main
    fn get_revisions(&self, doc_id: &str, rev_ids: Vec<i64>) -> BoxResultFuture<Vec<RevisionPB>, CollaborateError> {
        let kv_store = self.0.kv_store();
        let doc_id = doc_id.to_owned();
        let f = || async move {
            let mut repeated_revision = kv_store.batch_get_revisions(&doc_id, rev_ids).await?;
            Ok(repeated_revision.take_items().into())
<<<<<<< HEAD
>>>>>>> upstream/main
=======
>>>>>>> upstream/main
        };

        Box::pin(async move { f().await.map_err(server_error_to_collaborate_error) })
    }

<<<<<<< HEAD
<<<<<<< HEAD
    fn get_doc_revisions(&self, doc_id: &str) -> BoxResultFuture<Vec<Revision>, CollaborateError> {
        let kv_store = self.0.kv_store();
        let doc_id = doc_id.to_owned();
        let f = || async move {
            let mut pb = kv_store.get_doc_revisions(&doc_id).await?;
            let repeated_revision: RepeatedRevision = (&mut pb).try_into()?;
            let revisions = repeated_revision.into_inner();
            Ok(revisions)
=======
=======
>>>>>>> upstream/main
    fn get_doc_revisions(&self, doc_id: &str) -> BoxResultFuture<Vec<RevisionPB>, CollaborateError> {
        let kv_store = self.0.kv_store();
        let doc_id = doc_id.to_owned();
        let f = || async move {
            let mut repeated_revision = kv_store.get_doc_revisions(&doc_id).await?;
            Ok(repeated_revision.take_items().into())
<<<<<<< HEAD
>>>>>>> upstream/main
=======
>>>>>>> upstream/main
        };

        Box::pin(async move { f().await.map_err(server_error_to_collaborate_error) })
    }
<<<<<<< HEAD
<<<<<<< HEAD
=======
=======
>>>>>>> upstream/main

    fn reset_document(
        &self,
        doc_id: &str,
        mut repeated_revision: RepeatedRevisionPB,
    ) -> BoxResultFuture<(), CollaborateError> {
        let kv_store = self.0.kv_store();
        let doc_id = doc_id.to_owned();
        let f = || async move {
            kv_store
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
        Box::pin(async move { f().await.map_err(server_error_to_collaborate_error) })
    }
<<<<<<< HEAD
>>>>>>> upstream/main
=======
>>>>>>> upstream/main
}

fn server_error_to_collaborate_error(error: ServerError) -> CollaborateError {
    if error.is_record_not_found() {
        CollaborateError::record_not_found()
    } else {
        CollaborateError::internal().context(error)
    }
}
