use crate::entities::revision::{RepeatedRevision, Revision};
use crate::{
    entities::{text_block::DocumentPB, ws_data::ServerRevisionWSDataBuilder},
    errors::{internal_error, CollaborateError, CollaborateResult},
    protobuf::ClientRevisionWSData,
    server_document::document_pad::ServerDocument,
    synchronizer::{RevisionSyncPersistence, RevisionSyncResponse, RevisionSynchronizer, RevisionUser},
    util::rev_id_from_str,
};
use async_stream::stream;
use dashmap::DashMap;
use futures::stream::StreamExt;
use lib_infra::future::BoxResultFuture;
use lib_ot::core::AttributeHashMap;
use lib_ot::text_delta::TextOperations;
use std::{collections::HashMap, fmt::Debug, sync::Arc};
use tokio::{
    sync::{mpsc, oneshot, RwLock},
    task::spawn_blocking,
};

pub trait TextBlockCloudPersistence: Send + Sync + Debug {
    fn read_text_block(&self, doc_id: &str) -> BoxResultFuture<DocumentPB, CollaborateError>;

    fn create_text_block(
        &self,
        doc_id: &str,
        repeated_revision: RepeatedRevision,
    ) -> BoxResultFuture<Option<DocumentPB>, CollaborateError>;

    fn read_text_block_revisions(
        &self,
        doc_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> BoxResultFuture<Vec<Revision>, CollaborateError>;

    fn save_text_block_revisions(&self, repeated_revision: RepeatedRevision) -> BoxResultFuture<(), CollaborateError>;

    fn reset_text_block(
        &self,
        doc_id: &str,
        repeated_revision: RepeatedRevision,
    ) -> BoxResultFuture<(), CollaborateError>;
}

impl RevisionSyncPersistence for Arc<dyn TextBlockCloudPersistence> {
    fn read_revisions(
        &self,
        object_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> BoxResultFuture<Vec<Revision>, CollaborateError> {
        (**self).read_text_block_revisions(object_id, rev_ids)
    }

    fn save_revisions(&self, repeated_revision: RepeatedRevision) -> BoxResultFuture<(), CollaborateError> {
        (**self).save_text_block_revisions(repeated_revision)
    }

    fn reset_object(
        &self,
        object_id: &str,
        repeated_revision: RepeatedRevision,
    ) -> BoxResultFuture<(), CollaborateError> {
        (**self).reset_text_block(object_id, repeated_revision)
    }
}

pub struct ServerDocumentManager {
    document_handlers: Arc<RwLock<HashMap<String, Arc<OpenDocumentHandler>>>>,
    persistence: Arc<dyn TextBlockCloudPersistence>,
}

impl ServerDocumentManager {
    pub fn new(persistence: Arc<dyn TextBlockCloudPersistence>) -> Self {
        Self {
            document_handlers: Arc::new(RwLock::new(HashMap::new())),
            persistence,
        }
    }

    pub async fn handle_client_revisions(
        &self,
        user: Arc<dyn RevisionUser>,
        mut client_data: ClientRevisionWSData,
    ) -> Result<(), CollaborateError> {
        let repeated_revision: RepeatedRevision = client_data.take_revisions().into();
        let cloned_user = user.clone();
        let ack_id = rev_id_from_str(&client_data.data_id)?;
        let object_id = client_data.object_id;

        let result = match self.get_document_handler(&object_id).await {
            None => {
                tracing::trace!("Can't find the document. Creating the document {}", object_id);
                let _ = self.create_document(&object_id, repeated_revision).await.map_err(|e| {
                    CollaborateError::internal().context(format!("Server create document failed: {}", e))
                })?;
                Ok(())
            }
            Some(handler) => {
                let _ = handler.apply_revisions(user, repeated_revision).await?;
                Ok(())
            }
        };

        if result.is_ok() {
            cloned_user.receive(RevisionSyncResponse::Ack(
                ServerRevisionWSDataBuilder::build_ack_message(&object_id, ack_id),
            ));
        }
        result
    }

    pub async fn handle_client_ping(
        &self,
        user: Arc<dyn RevisionUser>,
        client_data: ClientRevisionWSData,
    ) -> Result<(), CollaborateError> {
        let rev_id = rev_id_from_str(&client_data.data_id)?;
        let doc_id = client_data.object_id.clone();
        match self.get_document_handler(&doc_id).await {
            None => {
                tracing::trace!("Document:{} doesn't exist, ignore client ping", doc_id);
                Ok(())
            }
            Some(handler) => {
                let _ = handler.apply_ping(rev_id, user).await?;
                Ok(())
            }
        }
    }

    pub async fn handle_document_reset(
        &self,
        doc_id: &str,
        mut repeated_revision: RepeatedRevision,
    ) -> Result<(), CollaborateError> {
        repeated_revision.sort_by(|a, b| a.rev_id.cmp(&b.rev_id));

        match self.get_document_handler(doc_id).await {
            None => {
                tracing::warn!("Document:{} doesn't exist, ignore document reset", doc_id);
                Ok(())
            }
            Some(handler) => {
                let _ = handler.apply_document_reset(repeated_revision).await?;
                Ok(())
            }
        }
    }

    async fn get_document_handler(&self, doc_id: &str) -> Option<Arc<OpenDocumentHandler>> {
        if let Some(handler) = self.document_handlers.read().await.get(doc_id).cloned() {
            return Some(handler);
        }

        let mut write_guard = self.document_handlers.write().await;
        match self.persistence.read_text_block(doc_id).await {
            Ok(doc) => {
                let handler = self.create_document_handler(doc).await.map_err(internal_error).unwrap();
                write_guard.insert(doc_id.to_owned(), handler.clone());
                drop(write_guard);
                Some(handler)
            }
            Err(_) => None,
        }
    }

    async fn create_document(
        &self,
        doc_id: &str,
        repeated_revision: RepeatedRevision,
    ) -> Result<Arc<OpenDocumentHandler>, CollaborateError> {
        match self.persistence.create_text_block(doc_id, repeated_revision).await? {
            None => Err(CollaborateError::internal().context("Create document info from revisions failed")),
            Some(doc) => {
                let handler = self.create_document_handler(doc).await?;
                self.document_handlers
                    .write()
                    .await
                    .insert(doc_id.to_owned(), handler.clone());
                Ok(handler)
            }
        }
    }

    #[tracing::instrument(level = "debug", skip(self, doc), err)]
    async fn create_document_handler(&self, doc: DocumentPB) -> Result<Arc<OpenDocumentHandler>, CollaborateError> {
        let persistence = self.persistence.clone();
        let handle = spawn_blocking(|| OpenDocumentHandler::new(doc, persistence))
            .await
            .map_err(|e| CollaborateError::internal().context(format!("Create document handler failed: {}", e)))?;
        Ok(Arc::new(handle?))
    }
}

impl std::ops::Drop for ServerDocumentManager {
    fn drop(&mut self) {
        log::trace!("ServerDocumentManager was dropped");
    }
}

type DocumentRevisionSynchronizer = RevisionSynchronizer<AttributeHashMap>;

struct OpenDocumentHandler {
    doc_id: String,
    sender: mpsc::Sender<DocumentCommand>,
    users: DashMap<String, Arc<dyn RevisionUser>>,
}

impl OpenDocumentHandler {
    fn new(doc: DocumentPB, persistence: Arc<dyn TextBlockCloudPersistence>) -> Result<Self, CollaborateError> {
        let doc_id = doc.block_id.clone();
        let (sender, receiver) = mpsc::channel(1000);
        let users = DashMap::new();

        let operations = TextOperations::from_bytes(&doc.text)?;
        let sync_object = ServerDocument::from_operations(&doc_id, operations);
        let synchronizer = Arc::new(DocumentRevisionSynchronizer::new(doc.rev_id, sync_object, persistence));

        let queue = DocumentCommandRunner::new(&doc.block_id, receiver, synchronizer);
        tokio::task::spawn(queue.run());
        Ok(Self { doc_id, sender, users })
    }

    #[tracing::instrument(
        name = "server_document_apply_revision",
        level = "trace",
        skip(self, user, repeated_revision),
        err
    )]
    async fn apply_revisions(
        &self,
        user: Arc<dyn RevisionUser>,
        repeated_revision: RepeatedRevision,
    ) -> Result<(), CollaborateError> {
        let (ret, rx) = oneshot::channel();
        self.users.insert(user.user_id(), user.clone());
        let msg = DocumentCommand::ApplyRevisions {
            user,
            repeated_revision,
            ret,
        };

        let result = self.send(msg, rx).await?;
        result
    }

    async fn apply_ping(&self, rev_id: i64, user: Arc<dyn RevisionUser>) -> Result<(), CollaborateError> {
        let (ret, rx) = oneshot::channel();
        self.users.insert(user.user_id(), user.clone());
        let msg = DocumentCommand::Ping { user, rev_id, ret };
        let result = self.send(msg, rx).await?;
        result
    }

    #[tracing::instrument(level = "debug", skip(self, repeated_revision), err)]
    async fn apply_document_reset(&self, repeated_revision: RepeatedRevision) -> Result<(), CollaborateError> {
        let (ret, rx) = oneshot::channel();
        let msg = DocumentCommand::Reset { repeated_revision, ret };
        let result = self.send(msg, rx).await?;
        result
    }

    async fn send<T>(&self, msg: DocumentCommand, rx: oneshot::Receiver<T>) -> CollaborateResult<T> {
        let _ = self
            .sender
            .send(msg)
            .await
            .map_err(|e| CollaborateError::internal().context(format!("Send document command failed: {}", e)))?;
        Ok(rx.await.map_err(internal_error)?)
    }
}

impl std::ops::Drop for OpenDocumentHandler {
    fn drop(&mut self) {
        tracing::trace!("{} OpenDocHandle was dropped", self.doc_id);
    }
}

// #[derive(Debug)]
enum DocumentCommand {
    ApplyRevisions {
        user: Arc<dyn RevisionUser>,
        repeated_revision: RepeatedRevision,
        ret: oneshot::Sender<CollaborateResult<()>>,
    },
    Ping {
        user: Arc<dyn RevisionUser>,
        rev_id: i64,
        ret: oneshot::Sender<CollaborateResult<()>>,
    },
    Reset {
        repeated_revision: RepeatedRevision,
        ret: oneshot::Sender<CollaborateResult<()>>,
    },
}

struct DocumentCommandRunner {
    pub doc_id: String,
    receiver: Option<mpsc::Receiver<DocumentCommand>>,
    synchronizer: Arc<DocumentRevisionSynchronizer>,
}

impl DocumentCommandRunner {
    fn new(
        doc_id: &str,
        receiver: mpsc::Receiver<DocumentCommand>,
        synchronizer: Arc<DocumentRevisionSynchronizer>,
    ) -> Self {
        Self {
            doc_id: doc_id.to_owned(),
            receiver: Some(receiver),
            synchronizer,
        }
    }

    async fn run(mut self) {
        let mut receiver = self
            .receiver
            .take()
            .expect("DocumentCommandRunner's receiver should only take one time");

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

    async fn handle_message(&self, msg: DocumentCommand) {
        match msg {
            DocumentCommand::ApplyRevisions {
                user,
                repeated_revision,
                ret,
            } => {
                let result = self
                    .synchronizer
                    .sync_revisions(user, repeated_revision)
                    .await
                    .map_err(internal_error);
                let _ = ret.send(result);
            }
            DocumentCommand::Ping { user, rev_id, ret } => {
                let result = self.synchronizer.pong(user, rev_id).await.map_err(internal_error);
                let _ = ret.send(result);
            }
            DocumentCommand::Reset { repeated_revision, ret } => {
                let result = self.synchronizer.reset(repeated_revision).await.map_err(internal_error);
                let _ = ret.send(result);
            }
        }
    }
}

impl std::ops::Drop for DocumentCommandRunner {
    fn drop(&mut self) {
        tracing::trace!("{} DocumentCommandQueue was dropped", self.doc_id);
    }
}
