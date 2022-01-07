use crate::{
    document::Document,
    entities::{doc::DocumentInfo, ws::DocumentServerWSDataBuilder},
    errors::{internal_error, CollaborateError, CollaborateResult},
    protobuf::{DocumentClientWSData, RepeatedRevision as RepeatedRevisionPB, Revision as RevisionPB},
    sync::{RevisionSynchronizer, RevisionUser, SyncResponse},
};
use async_stream::stream;
use dashmap::DashMap;
use futures::stream::StreamExt;
use lib_infra::future::BoxResultFuture;
use lib_ot::rich_text::RichTextDelta;
use std::{collections::HashMap, fmt::Debug, sync::Arc};
use tokio::{
    sync::{mpsc, oneshot, RwLock},
    task::spawn_blocking,
};

pub trait DocumentPersistence: Send + Sync + Debug {
    fn read_doc(&self, doc_id: &str) -> BoxResultFuture<DocumentInfo, CollaborateError>;

    fn create_doc(
        &self,
        doc_id: &str,
        repeated_revision: RepeatedRevisionPB,
    ) -> BoxResultFuture<DocumentInfo, CollaborateError>;

    fn get_revisions(&self, doc_id: &str, rev_ids: Vec<i64>) -> BoxResultFuture<Vec<RevisionPB>, CollaborateError>;

    fn get_doc_revisions(&self, doc_id: &str) -> BoxResultFuture<Vec<RevisionPB>, CollaborateError>;

    fn reset_document(
        &self,
        doc_id: &str,
        repeated_revision: RepeatedRevisionPB,
    ) -> BoxResultFuture<(), CollaborateError>;
}

pub struct ServerDocumentManager {
    open_doc_map: Arc<RwLock<HashMap<String, Arc<OpenDocHandle>>>>,
    persistence: Arc<dyn DocumentPersistence>,
}

impl ServerDocumentManager {
    pub fn new(persistence: Arc<dyn DocumentPersistence>) -> Self {
        Self {
            open_doc_map: Arc::new(RwLock::new(HashMap::new())),
            persistence,
        }
    }

    pub async fn handle_client_revisions(
        &self,
        user: Arc<dyn RevisionUser>,
        mut client_data: DocumentClientWSData,
    ) -> Result<(), CollaborateError> {
        let repeated_revision = client_data.take_revisions();
        let cloned_user = user.clone();
        let ack_id = rev_id_from_str(&client_data.id)?;
        let doc_id = client_data.doc_id;

        let result = match self.get_document_handler(&doc_id).await {
            None => {
                let _ = self.create_document(&doc_id, repeated_revision).await.map_err(|e| {
                    CollaborateError::internal().context(format!("Server crate document failed: {}", e))
                })?;
                Ok(())
            },
            Some(handler) => {
                let _ = handler.apply_revisions(user, repeated_revision).await?;
                Ok(())
            },
        };

        if result.is_ok() {
            cloned_user.receive(SyncResponse::Ack(DocumentServerWSDataBuilder::build_ack_message(
                &doc_id, ack_id,
            )));
        }
        result
    }

    pub async fn handle_client_ping(
        &self,
        user: Arc<dyn RevisionUser>,
        client_data: DocumentClientWSData,
    ) -> Result<(), CollaborateError> {
        let rev_id = rev_id_from_str(&client_data.id)?;
        let doc_id = client_data.doc_id.clone();
        match self.get_document_handler(&doc_id).await {
            None => {
                tracing::warn!("Document:{} doesn't exist, ignore pinging", doc_id);
                Ok(())
            },
            Some(handler) => {
                let _ = handler.apply_ping(rev_id, user).await?;
                Ok(())
            },
        }
    }

    pub async fn handle_document_reset(
        &self,
        doc_id: &str,
        mut repeated_revision: RepeatedRevisionPB,
    ) -> Result<(), CollaborateError> {
        repeated_revision.mut_items().sort_by(|a, b| a.rev_id.cmp(&b.rev_id));
        match self.get_document_handler(doc_id).await {
            None => {
                tracing::warn!("Document:{} doesn't exist, ignore document reset", doc_id);
                Ok(())
            },
            Some(handler) => {
                let _ = handler.apply_document_reset(repeated_revision).await?;
                Ok(())
            },
        }
    }

    async fn get_document_handler(&self, doc_id: &str) -> Option<Arc<OpenDocHandle>> {
        if let Some(handler) = self.open_doc_map.read().await.get(doc_id).cloned() {
            return Some(handler);
        }

        let mut write_guard = self.open_doc_map.write().await;
        match self.persistence.read_doc(doc_id).await {
            Ok(doc) => {
                let handler = self.create_document_handler(doc).await.map_err(internal_error).unwrap();
                write_guard.insert(doc_id.to_owned(), handler.clone());
                drop(write_guard);
                Some(handler)
            },
            Err(_) => None,
        }
    }

    #[tracing::instrument(level = "debug", skip(self, repeated_revision), err)]
    async fn create_document(
        &self,
        doc_id: &str,
        repeated_revision: RepeatedRevisionPB,
    ) -> Result<Arc<OpenDocHandle>, CollaborateError> {
        let doc = self.persistence.create_doc(doc_id, repeated_revision).await?;
        let handler = self.create_document_handler(doc).await?;
        self.open_doc_map
            .write()
            .await
            .insert(doc_id.to_owned(), handler.clone());
        Ok(handler)
    }

    async fn create_document_handler(&self, doc: DocumentInfo) -> Result<Arc<OpenDocHandle>, CollaborateError> {
        let persistence = self.persistence.clone();
        let handle = spawn_blocking(|| OpenDocHandle::new(doc, persistence))
            .await
            .map_err(|e| CollaborateError::internal().context(format!("Create open doc handler failed: {}", e)))?;
        Ok(Arc::new(handle?))
    }
}

impl std::ops::Drop for ServerDocumentManager {
    fn drop(&mut self) {
        log::debug!("ServerDocumentManager was drop");
    }
}

struct OpenDocHandle {
    doc_id: String,
    sender: mpsc::Sender<DocumentCommand>,
    persistence: Arc<dyn DocumentPersistence>,
    users: DashMap<String, Arc<dyn RevisionUser>>,
}

impl OpenDocHandle {
    fn new(doc: DocumentInfo, persistence: Arc<dyn DocumentPersistence>) -> Result<Self, CollaborateError> {
        let doc_id = doc.doc_id.clone();
        let (sender, receiver) = mpsc::channel(100);
        let users = DashMap::new();
        let queue = DocumentCommandQueue::new(receiver, doc)?;
        tokio::task::spawn(queue.run());
        Ok(Self {
            doc_id,
            sender,
            persistence,
            users,
        })
    }

    #[tracing::instrument(level = "debug", skip(self, user, repeated_revision), err)]
    async fn apply_revisions(
        &self,
        user: Arc<dyn RevisionUser>,
        repeated_revision: RepeatedRevisionPB,
    ) -> Result<(), CollaborateError> {
        let (ret, rx) = oneshot::channel();
        let persistence = self.persistence.clone();
        self.users.insert(user.user_id(), user.clone());
        let msg = DocumentCommand::ApplyRevisions {
            user,
            repeated_revision,
            persistence,
            ret,
        };

        let result = self.send(msg, rx).await?;
        result
    }

    async fn apply_ping(&self, rev_id: i64, user: Arc<dyn RevisionUser>) -> Result<(), CollaborateError> {
        let (ret, rx) = oneshot::channel();
        self.users.insert(user.user_id(), user.clone());
        let persistence = self.persistence.clone();
        let msg = DocumentCommand::Ping {
            user,
            persistence,
            rev_id,
            ret,
        };
        let result = self.send(msg, rx).await?;
        result
    }

    #[tracing::instrument(level = "debug", skip(self, repeated_revision), err)]
    async fn apply_document_reset(&self, repeated_revision: RepeatedRevisionPB) -> Result<(), CollaborateError> {
        let (ret, rx) = oneshot::channel();
        let persistence = self.persistence.clone();
        let msg = DocumentCommand::Reset {
            persistence,
            repeated_revision,
            ret,
        };
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

impl std::ops::Drop for OpenDocHandle {
    fn drop(&mut self) {
        //
        log::debug!("{} OpenDocHandle was drop", self.doc_id);
    }
}

// #[derive(Debug)]
enum DocumentCommand {
    ApplyRevisions {
        user: Arc<dyn RevisionUser>,
        repeated_revision: RepeatedRevisionPB,
        persistence: Arc<dyn DocumentPersistence>,
        ret: oneshot::Sender<CollaborateResult<()>>,
    },
    Ping {
        user: Arc<dyn RevisionUser>,
        persistence: Arc<dyn DocumentPersistence>,
        rev_id: i64,
        ret: oneshot::Sender<CollaborateResult<()>>,
    },
    Reset {
        persistence: Arc<dyn DocumentPersistence>,
        repeated_revision: RepeatedRevisionPB,
        ret: oneshot::Sender<CollaborateResult<()>>,
    },
}

struct DocumentCommandQueue {
    pub doc_id: String,
    receiver: Option<mpsc::Receiver<DocumentCommand>>,
    synchronizer: Arc<RevisionSynchronizer>,
}

impl DocumentCommandQueue {
    fn new(receiver: mpsc::Receiver<DocumentCommand>, doc: DocumentInfo) -> Result<Self, CollaborateError> {
        let delta = RichTextDelta::from_bytes(&doc.text)?;
        let synchronizer = Arc::new(RevisionSynchronizer::new(
            &doc.doc_id,
            doc.rev_id,
            Document::from_delta(delta),
        ));

        Ok(Self {
            doc_id: doc.doc_id,
            receiver: Some(receiver),
            synchronizer,
        })
    }

    async fn run(mut self) {
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

    async fn handle_message(&self, msg: DocumentCommand) {
        match msg {
            DocumentCommand::ApplyRevisions {
                user,
                repeated_revision,
                persistence,
                ret,
            } => {
                let result = self
                    .synchronizer
                    .sync_revisions(user, repeated_revision, persistence)
                    .await
                    .map_err(internal_error);
                let _ = ret.send(result);
            },
            DocumentCommand::Ping {
                user,
                persistence,
                rev_id,
                ret,
            } => {
                let result = self
                    .synchronizer
                    .pong(user, persistence, rev_id)
                    .await
                    .map_err(internal_error);
                let _ = ret.send(result);
            },
            DocumentCommand::Reset {
                persistence,
                repeated_revision,
                ret,
            } => {
                let result = self
                    .synchronizer
                    .reset(persistence, repeated_revision)
                    .await
                    .map_err(internal_error);
                let _ = ret.send(result);
            },
        }
    }
}

impl std::ops::Drop for DocumentCommandQueue {
    fn drop(&mut self) {
        log::debug!("{} DocumentCommandQueue was drop", self.doc_id);
    }
}

fn rev_id_from_str(s: &str) -> Result<i64, CollaborateError> {
    let rev_id = s
        .to_owned()
        .parse::<i64>()
        .map_err(|e| CollaborateError::internal().context(format!("Parse rev_id from {} failed. {}", s, e)))?;
    Ok(rev_id)
}
