use crate::{
    document::Document,
    entities::{
        doc::DocumentInfo,
        revision::{RepeatedRevision, Revision},
        ws::DocumentServerWSDataBuilder,
    },
    errors::{internal_error, CollaborateError, CollaborateResult},
    protobuf::DocumentClientWSData,
    sync::{RevisionSynchronizer, RevisionUser, SyncResponse},
};
use async_stream::stream;
use dashmap::DashMap;
use futures::stream::StreamExt;
use lib_infra::future::BoxResultFuture;
use lib_ot::rich_text::RichTextDelta;
use std::{convert::TryFrom, fmt::Debug, sync::Arc};
use tokio::{
    sync::{mpsc, oneshot},
    task::spawn_blocking,
};

pub trait DocumentPersistence: Send + Sync + Debug {
    fn read_doc(&self, doc_id: &str) -> BoxResultFuture<DocumentInfo, CollaborateError>;
    fn create_doc(&self, doc_id: &str, revisions: Vec<Revision>) -> BoxResultFuture<DocumentInfo, CollaborateError>;
    fn get_revisions(&self, doc_id: &str, rev_ids: Vec<i64>) -> BoxResultFuture<Vec<Revision>, CollaborateError>;
    fn get_doc_revisions(&self, doc_id: &str) -> BoxResultFuture<Vec<Revision>, CollaborateError>;
}

pub struct ServerDocumentManager {
    open_doc_map: DashMap<String, Arc<OpenDocHandle>>,
    persistence: Arc<dyn DocumentPersistence>,
}

impl ServerDocumentManager {
    pub fn new(persistence: Arc<dyn DocumentPersistence>) -> Self {
        Self {
            open_doc_map: DashMap::new(),
            persistence,
        }
    }

    pub async fn handle_client_revisions(
        &self,
        user: Arc<dyn RevisionUser>,
        mut client_data: DocumentClientWSData,
    ) -> Result<(), CollaborateError> {
        let mut pb = client_data.take_revisions();
        let cloned_user = user.clone();
        let ack_id = rev_id_from_str(&client_data.id)?;
        let doc_id = client_data.doc_id;

        let revisions = spawn_blocking(move || {
            let repeated_revision = RepeatedRevision::try_from(&mut pb)?;
            let revisions = repeated_revision.into_inner();
            Ok::<Vec<Revision>, CollaborateError>(revisions)
        })
        .await
        .map_err(internal_error)??;

        let result = match self.get_document_handler(&doc_id).await {
            None => {
                let _ = self.create_document(&doc_id, revisions).await.map_err(|e| {
                    CollaborateError::internal().context(format!("Server crate document failed: {}", e))
                })?;
                Ok(())
            },
            Some(handler) => {
                let _ = handler.apply_revisions(doc_id.clone(), user, revisions).await?;
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
            None => Ok(()),
            Some(handler) => {
                let _ = handler.apply_ping(doc_id.clone(), rev_id, user).await?;
                Ok(())
            },
        }
    }

    async fn get_document_handler(&self, doc_id: &str) -> Option<Arc<OpenDocHandle>> {
        match self.open_doc_map.get(doc_id).map(|ctx| ctx.clone()) {
            Some(edit_doc) => Some(edit_doc),
            None => {
                let f = || async {
                    let doc = self.persistence.read_doc(doc_id).await?;
                    let handler = self.cache_document(doc).await.map_err(internal_error)?;
                    Ok::<Arc<OpenDocHandle>, CollaborateError>(handler)
                };
                match f().await {
                    Ok(handler) => Some(handler),
                    Err(e) => {
                        log::error!("{}", e);
                        None
                    },
                }
            },
        }
    }

    #[tracing::instrument(level = "debug", skip(self, revisions), err)]
    async fn create_document(
        &self,
        doc_id: &str,
        revisions: Vec<Revision>,
    ) -> Result<Arc<OpenDocHandle>, CollaborateError> {
        let doc = self.persistence.create_doc(doc_id, revisions).await?;
        let handler = self.cache_document(doc).await?;
        Ok(handler)
    }

    async fn cache_document(&self, doc: DocumentInfo) -> Result<Arc<OpenDocHandle>, CollaborateError> {
        let doc_id = doc.doc_id.clone();
        let persistence = self.persistence.clone();
        let handle = spawn_blocking(|| OpenDocHandle::new(doc, persistence))
            .await
            .map_err(|e| CollaborateError::internal().context(format!("Create open doc handler failed: {}", e)))?;
        let handle = Arc::new(handle?);
        self.open_doc_map.insert(doc_id, handle.clone());
        Ok(handle)
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

    #[tracing::instrument(level = "debug", skip(self, user, revisions), err)]
    async fn apply_revisions(
        &self,
        doc_id: String,
        user: Arc<dyn RevisionUser>,
        revisions: Vec<Revision>,
    ) -> Result<(), CollaborateError> {
        let (ret, rx) = oneshot::channel();
        let persistence = self.persistence.clone();
        self.users.insert(user.user_id(), user.clone());
        let msg = DocumentCommand::ApplyRevisions {
            doc_id,
            user,
            revisions,
            persistence,
            ret,
        };

        let _ = self.send(msg, rx).await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, user), err)]
    async fn apply_ping(
        &self,
        doc_id: String,
        rev_id: i64,
        user: Arc<dyn RevisionUser>,
    ) -> Result<(), CollaborateError> {
        let (ret, rx) = oneshot::channel();
        self.users.insert(user.user_id(), user.clone());
        let persistence = self.persistence.clone();
        let msg = DocumentCommand::Ping {
            doc_id,
            user,
            persistence,
            rev_id,
            ret,
        };
        let _ = self.send(msg, rx).await?;
        Ok(())
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
        log::debug!("{} OpenDocHandle drop", self.doc_id);
    }
}

// #[derive(Debug)]
enum DocumentCommand {
    ApplyRevisions {
        doc_id: String,
        user: Arc<dyn RevisionUser>,
        revisions: Vec<Revision>,
        persistence: Arc<dyn DocumentPersistence>,
        ret: oneshot::Sender<CollaborateResult<()>>,
    },
    Ping {
        doc_id: String,
        user: Arc<dyn RevisionUser>,
        persistence: Arc<dyn DocumentPersistence>,
        rev_id: i64,
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
                doc_id,
                user,
                revisions,
                persistence,
                ret,
            } => {
                let result = self
                    .synchronizer
                    .sync_revisions(doc_id, user, revisions, persistence)
                    .await
                    .map_err(internal_error);
                let _ = ret.send(result);
            },
            DocumentCommand::Ping {
                doc_id,
                user,
                persistence,
                rev_id,
                ret,
            } => {
                let result = self
                    .synchronizer
                    .pong(doc_id, user, persistence, rev_id)
                    .await
                    .map_err(internal_error);
                let _ = ret.send(result);
            },
        }
    }
}

impl std::ops::Drop for DocumentCommandQueue {
    fn drop(&mut self) {
        log::debug!("{} DocumentCommandQueue drop", self.doc_id);
    }
}

fn rev_id_from_str(s: &str) -> Result<i64, CollaborateError> {
    let rev_id = s
        .to_owned()
        .parse::<i64>()
        .map_err(|e| CollaborateError::internal().context(format!("Parse rev_id from {} failed. {}", s, e)))?;
    Ok(rev_id)
}
