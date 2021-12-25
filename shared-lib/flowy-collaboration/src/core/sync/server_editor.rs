use crate::{
    core::{
        document::Document,
        sync::{RevisionSynchronizer, RevisionUser},
    },
    entities::{doc::DocumentInfo, revision::Revision},
    errors::{internal_error, CollaborateError, CollaborateResult},
};
use async_stream::stream;
use dashmap::DashMap;
use futures::stream::StreamExt;
use lib_infra::future::FutureResultSend;
use lib_ot::rich_text::RichTextDelta;
use std::{fmt::Debug, sync::Arc};
use tokio::{
    sync::{mpsc, oneshot},
    task::spawn_blocking,
};

pub trait DocumentPersistence: Send + Sync + Debug {
    fn read_doc(&self, doc_id: &str) -> FutureResultSend<DocumentInfo, CollaborateError>;
    fn create_doc(&self, revision: Revision) -> FutureResultSend<DocumentInfo, CollaborateError>;
    fn get_revisions(&self, doc_id: &str, rev_ids: Vec<i64>) -> FutureResultSend<Vec<Revision>, CollaborateError>;
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

    pub async fn apply_revisions(
        &self,
        user: Arc<dyn RevisionUser>,
        revisions: Vec<Revision>,
    ) -> Result<(), CollaborateError> {
        if revisions.is_empty() {
            return Ok(());
        }
        let revision = revisions.first().unwrap();
        let handler = match self.get_document_handler(&revision.doc_id).await {
            None => {
                // Create the document if it doesn't exist
                self.create_document(revision.clone()).await.map_err(internal_error)?
            },
            Some(handler) => handler,
        };

        handler.apply_revisions(user, revisions).await.map_err(internal_error)?;
        Ok(())
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

    async fn create_document(&self, revision: Revision) -> Result<Arc<OpenDocHandle>, CollaborateError> {
        let doc = self.persistence.create_doc(revision).await?;
        let handler = self.cache_document(doc).await?;
        Ok(handler)
    }

    async fn cache_document(&self, doc: DocumentInfo) -> Result<Arc<OpenDocHandle>, CollaborateError> {
        let doc_id = doc.id.clone();
        let persistence = self.persistence.clone();
        let handle = spawn_blocking(|| OpenDocHandle::new(doc, persistence))
            .await
            .map_err(internal_error)?;
        let handle = Arc::new(handle?);
        self.open_doc_map.insert(doc_id, handle.clone());
        Ok(handle)
    }
}

struct OpenDocHandle {
    sender: mpsc::Sender<EditCommand>,
    persistence: Arc<dyn DocumentPersistence>,
}

impl OpenDocHandle {
    fn new(doc: DocumentInfo, persistence: Arc<dyn DocumentPersistence>) -> Result<Self, CollaborateError> {
        let (sender, receiver) = mpsc::channel(100);
        let queue = EditCommandQueue::new(receiver, doc)?;
        tokio::task::spawn(queue.run());
        Ok(Self { sender, persistence })
    }

    async fn apply_revisions(
        &self,
        user: Arc<dyn RevisionUser>,
        revisions: Vec<Revision>,
    ) -> Result<(), CollaborateError> {
        let (ret, rx) = oneshot::channel();
        let persistence = self.persistence.clone();
        let msg = EditCommand::ApplyRevisions {
            user,
            revisions,
            persistence,
            ret,
        };
        let _ = self.send(msg, rx).await?;
        Ok(())
    }

    pub async fn document_json(&self) -> CollaborateResult<String> {
        let (ret, rx) = oneshot::channel();
        let msg = EditCommand::GetDocumentJson { ret };
        self.send(msg, rx).await?
    }

    async fn send<T>(&self, msg: EditCommand, rx: oneshot::Receiver<T>) -> CollaborateResult<T> {
        let _ = self.sender.send(msg).await.map_err(internal_error)?;
        let result = rx.await.map_err(internal_error)?;
        Ok(result)
    }
}

#[derive(Debug)]
enum EditCommand {
    ApplyRevisions {
        user: Arc<dyn RevisionUser>,
        revisions: Vec<Revision>,
        persistence: Arc<dyn DocumentPersistence>,
        ret: oneshot::Sender<CollaborateResult<()>>,
    },
    GetDocumentJson {
        ret: oneshot::Sender<CollaborateResult<String>>,
    },
}

struct EditCommandQueue {
    pub doc_id: String,
    receiver: Option<mpsc::Receiver<EditCommand>>,
    synchronizer: Arc<RevisionSynchronizer>,
    users: DashMap<String, Arc<dyn RevisionUser>>,
}

impl EditCommandQueue {
    fn new(receiver: mpsc::Receiver<EditCommand>, doc: DocumentInfo) -> Result<Self, CollaborateError> {
        let delta = RichTextDelta::from_bytes(&doc.text)?;
        let users = DashMap::new();
        let synchronizer = Arc::new(RevisionSynchronizer::new(
            &doc.id,
            doc.rev_id,
            Document::from_delta(delta),
        ));

        Ok(Self {
            doc_id: doc.id,
            receiver: Some(receiver),
            synchronizer,
            users,
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

    async fn handle_message(&self, msg: EditCommand) {
        match msg {
            EditCommand::ApplyRevisions {
                user,
                revisions,
                persistence,
                ret,
            } => {
                self.users.insert(user.user_id(), user.clone());
                self.synchronizer
                    .apply_revisions(user, revisions, persistence)
                    .await
                    .unwrap();
                let _ = ret.send(Ok(()));
            },
            EditCommand::GetDocumentJson { ret } => {
                let synchronizer = self.synchronizer.clone();
                let json = spawn_blocking(move || synchronizer.doc_json())
                    .await
                    .map_err(internal_error);
                let _ = ret.send(json);
            },
        }
    }
}
