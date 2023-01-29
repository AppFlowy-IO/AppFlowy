use crate::server_folder::folder_pad::{FolderOperations, FolderRevisionSynchronizer};
use crate::{
    errors::{internal_error, CollaborateError, CollaborateResult},
    server_folder::folder_pad::ServerFolder,
    synchronizer::{RevisionSyncPersistence, RevisionSyncResponse, RevisionUser},
};
use async_stream::stream;
use flowy_http_model::entities::ClientRevisionWSData;
use flowy_http_model::folder::FolderInfo;
use flowy_http_model::revision::Revision;
use flowy_http_model::ws_data::ServerRevisionWSDataBuilder;
use futures::stream::StreamExt;
use lib_infra::future::BoxResultFuture;
use std::{collections::HashMap, fmt::Debug, sync::Arc};
use tokio::{
    sync::{mpsc, oneshot, RwLock},
    task::spawn_blocking,
};

pub trait FolderCloudPersistence: Send + Sync + Debug {
    fn read_folder(&self, user_id: &str, folder_id: &str) -> BoxResultFuture<FolderInfo, CollaborateError>;

    fn create_folder(
        &self,
        user_id: &str,
        folder_id: &str,
        revisions: Vec<Revision>,
    ) -> BoxResultFuture<Option<FolderInfo>, CollaborateError>;

    fn save_folder_revisions(&self, revisions: Vec<Revision>) -> BoxResultFuture<(), CollaborateError>;

    fn read_folder_revisions(
        &self,
        folder_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> BoxResultFuture<Vec<Revision>, CollaborateError>;

    fn reset_folder(&self, folder_id: &str, revisions: Vec<Revision>) -> BoxResultFuture<(), CollaborateError>;
}

impl RevisionSyncPersistence for Arc<dyn FolderCloudPersistence> {
    fn read_revisions(
        &self,
        object_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> BoxResultFuture<Vec<Revision>, CollaborateError> {
        (**self).read_folder_revisions(object_id, rev_ids)
    }

    fn save_revisions(&self, revisions: Vec<Revision>) -> BoxResultFuture<(), CollaborateError> {
        (**self).save_folder_revisions(revisions)
    }

    fn reset_object(&self, object_id: &str, revisions: Vec<Revision>) -> BoxResultFuture<(), CollaborateError> {
        (**self).reset_folder(object_id, revisions)
    }
}

pub struct ServerFolderManager {
    folder_handlers: Arc<RwLock<HashMap<String, Arc<OpenFolderHandler>>>>,
    persistence: Arc<dyn FolderCloudPersistence>,
}

impl ServerFolderManager {
    pub fn new(persistence: Arc<dyn FolderCloudPersistence>) -> Self {
        Self {
            folder_handlers: Arc::new(RwLock::new(HashMap::new())),
            persistence,
        }
    }

    pub async fn handle_client_revisions(
        &self,
        user: Arc<dyn RevisionUser>,
        client_data: ClientRevisionWSData,
    ) -> Result<(), CollaborateError> {
        let cloned_user = user.clone();
        let ack_id = client_data.rev_id;
        let folder_id = client_data.object_id;
        let user_id = user.user_id();

        let result = match self.get_folder_handler(&user_id, &folder_id).await {
            None => {
                let _ = self
                    .create_folder(&user_id, &folder_id, client_data.revisions)
                    .await
                    .map_err(|e| CollaborateError::internal().context(format!("Server create folder failed: {}", e)))?;
                Ok(())
            }
            Some(handler) => {
                handler.apply_revisions(user, client_data.revisions).await?;
                Ok(())
            }
        };

        if result.is_ok() {
            cloned_user.receive(RevisionSyncResponse::Ack(
                ServerRevisionWSDataBuilder::build_ack_message(&folder_id, ack_id),
            ));
        }
        result
    }

    pub async fn handle_client_ping(
        &self,
        user: Arc<dyn RevisionUser>,
        client_data: ClientRevisionWSData,
    ) -> Result<(), CollaborateError> {
        let user_id = user.user_id();
        let rev_id = client_data.rev_id;
        let folder_id = client_data.object_id.clone();
        match self.get_folder_handler(&user_id, &folder_id).await {
            None => {
                tracing::trace!("Folder:{} doesn't exist, ignore client ping", folder_id);
                Ok(())
            }
            Some(handler) => {
                handler.apply_ping(rev_id, user).await?;
                Ok(())
            }
        }
    }

    async fn get_folder_handler(&self, user_id: &str, folder_id: &str) -> Option<Arc<OpenFolderHandler>> {
        let folder_id = folder_id.to_owned();
        if let Some(handler) = self.folder_handlers.read().await.get(&folder_id).cloned() {
            return Some(handler);
        }

        let mut write_guard = self.folder_handlers.write().await;
        match self.persistence.read_folder(user_id, &folder_id).await {
            Ok(folder_info) => {
                let handler = self
                    .create_folder_handler(folder_info)
                    .await
                    .map_err(internal_error)
                    .unwrap();
                write_guard.insert(folder_id, handler.clone());
                drop(write_guard);
                Some(handler)
            }
            Err(_) => None,
        }
    }

    async fn create_folder_handler(&self, folder_info: FolderInfo) -> Result<Arc<OpenFolderHandler>, CollaborateError> {
        let persistence = self.persistence.clone();
        let handle = spawn_blocking(|| OpenFolderHandler::new(folder_info, persistence))
            .await
            .map_err(|e| CollaborateError::internal().context(format!("Create folder handler failed: {}", e)))?;
        Ok(Arc::new(handle?))
    }

    #[tracing::instrument(level = "debug", skip(self, revisions), err)]
    async fn create_folder(
        &self,
        user_id: &str,
        folder_id: &str,
        revisions: Vec<Revision>,
    ) -> Result<Arc<OpenFolderHandler>, CollaborateError> {
        match self.persistence.create_folder(user_id, folder_id, revisions).await? {
            Some(folder_info) => {
                let handler = self.create_folder_handler(folder_info).await?;
                self.folder_handlers
                    .write()
                    .await
                    .insert(folder_id.to_owned(), handler.clone());
                Ok(handler)
            }
            None => Err(CollaborateError::internal().context(String::new())),
        }
    }
}

struct OpenFolderHandler {
    folder_id: String,
    sender: mpsc::Sender<FolderCommand>,
}

impl OpenFolderHandler {
    fn new(folder_info: FolderInfo, persistence: Arc<dyn FolderCloudPersistence>) -> CollaborateResult<Self> {
        let (sender, receiver) = mpsc::channel(1000);
        let folder_id = folder_info.folder_id.clone();
        let operations = FolderOperations::from_bytes(&folder_info.text)?;
        let sync_object = ServerFolder::from_operations(&folder_id, operations);
        let synchronizer = Arc::new(FolderRevisionSynchronizer::new(
            folder_info.rev_id,
            sync_object,
            persistence,
        ));

        let queue = FolderCommandRunner::new(&folder_id, receiver, synchronizer);
        tokio::task::spawn(queue.run());

        Ok(Self { folder_id, sender })
    }

    #[tracing::instrument(
        name = "server_folder_apply_revision",
        level = "trace",
        skip(self, user, revisions),
        err
    )]
    async fn apply_revisions(&self, user: Arc<dyn RevisionUser>, revisions: Vec<Revision>) -> CollaborateResult<()> {
        let (ret, rx) = oneshot::channel();
        let msg = FolderCommand::ApplyRevisions { user, revisions, ret };

        self.send(msg, rx).await?
    }

    async fn apply_ping(&self, rev_id: i64, user: Arc<dyn RevisionUser>) -> Result<(), CollaborateError> {
        let (ret, rx) = oneshot::channel();
        let msg = FolderCommand::Ping { user, rev_id, ret };
        self.send(msg, rx).await?
    }

    async fn send<T>(&self, msg: FolderCommand, rx: oneshot::Receiver<T>) -> CollaborateResult<T> {
        self.sender
            .send(msg)
            .await
            .map_err(|e| CollaborateError::internal().context(format!("Send folder command failed: {}", e)))?;
        rx.await.map_err(internal_error)
    }
}

impl std::ops::Drop for OpenFolderHandler {
    fn drop(&mut self) {
        tracing::trace!("{} OpenFolderHandler was dropped", self.folder_id);
    }
}

enum FolderCommand {
    ApplyRevisions {
        user: Arc<dyn RevisionUser>,
        revisions: Vec<Revision>,
        ret: oneshot::Sender<CollaborateResult<()>>,
    },
    Ping {
        user: Arc<dyn RevisionUser>,
        rev_id: i64,
        ret: oneshot::Sender<CollaborateResult<()>>,
    },
}

struct FolderCommandRunner {
    folder_id: String,
    receiver: Option<mpsc::Receiver<FolderCommand>>,
    synchronizer: Arc<FolderRevisionSynchronizer>,
}
impl FolderCommandRunner {
    fn new(
        folder_id: &str,
        receiver: mpsc::Receiver<FolderCommand>,
        synchronizer: Arc<FolderRevisionSynchronizer>,
    ) -> Self {
        Self {
            folder_id: folder_id.to_owned(),
            receiver: Some(receiver),
            synchronizer,
        }
    }

    async fn run(mut self) {
        let mut receiver = self
            .receiver
            .take()
            .expect("FolderCommandRunner's receiver should only take one time");

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

    async fn handle_message(&self, msg: FolderCommand) {
        match msg {
            FolderCommand::ApplyRevisions { user, revisions, ret } => {
                let result = self
                    .synchronizer
                    .sync_revisions(user, revisions)
                    .await
                    .map_err(internal_error);
                let _ = ret.send(result);
            }
            FolderCommand::Ping { user, rev_id, ret } => {
                let result = self.synchronizer.pong(user, rev_id).await.map_err(internal_error);
                let _ = ret.send(result);
            }
        }
    }
}

impl std::ops::Drop for FolderCommandRunner {
    fn drop(&mut self) {
        tracing::trace!("{} FolderCommandRunner was dropped", self.folder_id);
    }
}
