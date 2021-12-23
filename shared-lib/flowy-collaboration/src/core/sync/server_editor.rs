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
use lib_ot::{errors::OTError, rich_text::RichTextDelta};
use std::sync::{atomic::Ordering::SeqCst, Arc};
use tokio::{
    sync::{mpsc, oneshot},
    task::spawn_blocking,
};

pub trait DocumentPersistence: Send + Sync {
    // fn update_doc(&self, doc_id: &str, rev_id: i64, delta: RichTextDelta) ->
    // FutureResultSend<(), CollaborateError>;
    fn read_doc(&self, doc_id: &str) -> FutureResultSend<DocumentInfo, CollaborateError>;
    fn create_doc(&self, revision: Revision) -> FutureResultSend<DocumentInfo, CollaborateError>;
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

    pub async fn get(&self, doc_id: &str) -> Option<Arc<OpenDocHandle>> {
        match self.open_doc_map.get(doc_id).map(|ctx| ctx.clone()) {
            Some(edit_doc) => Some(edit_doc),
            None => {
                let f = || async {
                    let doc = self.persistence.read_doc(doc_id).await?;
                    let handler = self.cache(doc).await.map_err(internal_error)?;
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

    pub async fn create_doc(&self, revision: Revision) -> Result<Arc<OpenDocHandle>, CollaborateError> {
        let doc = self.persistence.create_doc(revision).await?;
        let handler = self.cache(doc).await?;
        Ok(handler)
    }

    async fn cache(&self, doc: DocumentInfo) -> Result<Arc<OpenDocHandle>, CollaborateError> {
        let doc_id = doc.id.clone();
        let handle = spawn_blocking(|| OpenDocHandle::new(doc))
            .await
            .map_err(internal_error)?;
        let handle = Arc::new(handle?);
        self.open_doc_map.insert(doc_id, handle.clone());
        Ok(handle)
    }
}

pub struct OpenDocHandle {
    sender: mpsc::Sender<DocCommand>,
}

impl OpenDocHandle {
    pub fn new(doc: DocumentInfo) -> Result<Self, CollaborateError> {
        let (sender, receiver) = mpsc::channel(100);
        let queue = DocCommandQueue::new(receiver, doc)?;
        tokio::task::spawn(queue.run());
        Ok(Self { sender })
    }

    pub async fn apply_revision(
        &self,
        user: Arc<dyn RevisionUser>,
        revision: Revision,
    ) -> Result<(), CollaborateError> {
        let (ret, rx) = oneshot::channel();
        let msg = DocCommand::ReceiveRevision { user, revision, ret };
        let _ = self.send(msg, rx).await?;
        Ok(())
    }

    pub async fn document_json(&self) -> CollaborateResult<String> {
        let (ret, rx) = oneshot::channel();
        let msg = DocCommand::GetDocJson { ret };
        self.send(msg, rx).await?
    }

    pub async fn rev_id(&self) -> CollaborateResult<i64> {
        let (ret, rx) = oneshot::channel();
        let msg = DocCommand::GetDocRevId { ret };
        self.send(msg, rx).await?
    }

    async fn send<T>(&self, msg: DocCommand, rx: oneshot::Receiver<T>) -> CollaborateResult<T> {
        let _ = self.sender.send(msg).await.map_err(internal_error)?;
        let result = rx.await.map_err(internal_error)?;
        Ok(result)
    }
}

#[derive(Debug)]
enum DocCommand {
    ReceiveRevision {
        user: Arc<dyn RevisionUser>,
        revision: Revision,
        ret: oneshot::Sender<CollaborateResult<()>>,
    },
    GetDocJson {
        ret: oneshot::Sender<CollaborateResult<String>>,
    },
    GetDocRevId {
        ret: oneshot::Sender<CollaborateResult<i64>>,
    },
}

struct DocCommandQueue {
    receiver: Option<mpsc::Receiver<DocCommand>>,
    edit_doc: Arc<ServerDocEditor>,
}

impl DocCommandQueue {
    fn new(receiver: mpsc::Receiver<DocCommand>, doc: DocumentInfo) -> Result<Self, CollaborateError> {
        let edit_doc = Arc::new(ServerDocEditor::new(doc).map_err(internal_error)?);
        Ok(Self {
            receiver: Some(receiver),
            edit_doc,
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

    async fn handle_message(&self, msg: DocCommand) {
        match msg {
            DocCommand::ReceiveRevision { user, revision, ret } => {
                // let revision = (&mut revision).try_into().map_err(internal_error).unwrap();
                let _ = ret.send(
                    self.edit_doc
                        .apply_revision(user, revision)
                        .await
                        .map_err(internal_error),
                );
            },
            DocCommand::GetDocJson { ret } => {
                let edit_context = self.edit_doc.clone();
                let json = spawn_blocking(move || edit_context.document_json())
                    .await
                    .map_err(internal_error);
                let _ = ret.send(json);
            },
            DocCommand::GetDocRevId { ret } => {
                let _ = ret.send(Ok(self.edit_doc.rev_id()));
            },
        }
    }
}

#[rustfmt::skip]
//                                ┌──────────────────────┐     ┌────────────┐
//                           ┌───▶│ RevisionSynchronizer │────▶│  Document  │
//                           │    └──────────────────────┘     └────────────┘
//     ┌────────────────┐    │
// ───▶│ServerDocEditor │────┤
//     └────────────────┘    │
//                           │
//                           │    ┌────────┐       ┌────────────┐
//                           └───▶│ Users  │◆──────│RevisionUser│
//                                └────────┘       └────────────┘
pub struct ServerDocEditor {
    pub doc_id: String,
    synchronizer: Arc<RevisionSynchronizer>,
    users: DashMap<String, Arc<dyn RevisionUser>>,
}

impl ServerDocEditor {
    pub fn new(doc: DocumentInfo) -> Result<Self, OTError> {
        let delta = RichTextDelta::from_bytes(&doc.text)?;
        let users = DashMap::new();
        let synchronizer = Arc::new(RevisionSynchronizer::new(
            &doc.id,
            doc.rev_id,
            Document::from_delta(delta),
        ));

        Ok(Self {
            doc_id: doc.id,
            synchronizer,
            users,
        })
    }

    pub async fn apply_revision(&self, user: Arc<dyn RevisionUser>, revision: Revision) -> Result<(), OTError> {
        self.users.insert(user.user_id(), user.clone());
        self.synchronizer.apply_revision(user, revision).unwrap();
        Ok(())
    }

    pub fn document_json(&self) -> String { self.synchronizer.doc_json() }

    pub fn rev_id(&self) -> i64 { self.synchronizer.rev_id.load(SeqCst) }
}
