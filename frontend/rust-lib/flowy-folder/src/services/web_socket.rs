use crate::services::FOLDER_SYNC_INTERVAL_IN_MILLIS;
use bytes::Bytes;
use flowy_database::ConnectionPool;
use flowy_error::{FlowyError, FlowyResult};
use flowy_revision::*;
use flowy_sync::entities::revision::Revision;
use flowy_sync::server_folder::FolderOperations;
use flowy_sync::util::make_operations_from_revisions;
use flowy_sync::{
    client_folder::FolderPad,
    entities::{
        revision::RevisionRange,
        ws_data::{ClientRevisionWSData, NewDocumentUser, ServerRevisionWSDataType},
    },
};
use lib_infra::future::{BoxResultFuture, FutureResult};
use lib_ot::core::OperationTransform;
use parking_lot::RwLock;
use std::{sync::Arc, time::Duration};

#[derive(Clone)]
pub struct FolderResolveOperations(pub FolderOperations);
impl OperationsDeserializer<FolderResolveOperations> for FolderResolveOperations {
    fn deserialize_revisions(revisions: Vec<Revision>) -> FlowyResult<FolderResolveOperations> {
        Ok(FolderResolveOperations(make_operations_from_revisions(revisions)?))
    }
}

impl OperationsSerializer for FolderResolveOperations {
    fn serialize_operations(&self) -> Bytes {
        self.0.json_bytes()
    }
}

impl FolderResolveOperations {
    pub fn into_inner(self) -> FolderOperations {
        self.0
    }
}

pub type FolderConflictController = ConflictController<FolderResolveOperations>;

#[allow(dead_code)]
pub(crate) async fn make_folder_ws_manager(
    user_id: &str,
    folder_id: &str,
    rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
    web_socket: Arc<dyn RevisionWebSocket>,
    folder_pad: Arc<RwLock<FolderPad>>,
) -> Arc<RevisionWebSocketManager> {
    let ws_data_provider = Arc::new(WSDataProvider::new(folder_id, Arc::new(rev_manager.clone())));
    let resolver = Arc::new(FolderConflictResolver { folder_pad });
    let conflict_controller =
        FolderConflictController::new(user_id, resolver, Arc::new(ws_data_provider.clone()), rev_manager);
    let ws_data_stream = Arc::new(FolderRevisionWSDataStream::new(conflict_controller));
    let ws_data_sink = Arc::new(FolderWSDataSink(ws_data_provider));
    let ping_duration = Duration::from_millis(FOLDER_SYNC_INTERVAL_IN_MILLIS);
    Arc::new(RevisionWebSocketManager::new(
        "Folder",
        folder_id,
        web_socket,
        ws_data_sink,
        ws_data_stream,
        ping_duration,
    ))
}

pub(crate) struct FolderWSDataSink(Arc<WSDataProvider>);
impl RevisionWebSocketSink for FolderWSDataSink {
    fn next(&self) -> FutureResult<Option<ClientRevisionWSData>, FlowyError> {
        let sink_provider = self.0.clone();
        FutureResult::new(async move { sink_provider.next().await })
    }
}

struct FolderConflictResolver {
    folder_pad: Arc<RwLock<FolderPad>>,
}

impl ConflictResolver<FolderResolveOperations> for FolderConflictResolver {
    fn compose_operations(&self, operations: FolderResolveOperations) -> BoxResultFuture<OperationsMD5, FlowyError> {
        let operations = operations.into_inner();
        let folder_pad = self.folder_pad.clone();
        Box::pin(async move {
            let md5 = folder_pad.write().compose_remote_operations(operations)?;
            Ok(md5)
        })
    }

    fn transform_operations(
        &self,
        operations: FolderResolveOperations,
    ) -> BoxResultFuture<TransformOperations<FolderResolveOperations>, FlowyError> {
        let folder_pad = self.folder_pad.clone();
        let operations = operations.into_inner();
        Box::pin(async move {
            let read_guard = folder_pad.read();
            let mut server_operations: Option<FolderResolveOperations> = None;
            let client_operations: FolderResolveOperations;
            if read_guard.is_empty() {
                // Do nothing
                client_operations = FolderResolveOperations(operations);
            } else {
                let (s_prime, c_prime) = read_guard.get_operations().transform(&operations)?;
                client_operations = FolderResolveOperations(c_prime);
                server_operations = Some(FolderResolveOperations(s_prime));
            }
            drop(read_guard);
            Ok(TransformOperations {
                client_operations,
                server_operations,
            })
        })
    }

    fn reset_operations(&self, operations: FolderResolveOperations) -> BoxResultFuture<OperationsMD5, FlowyError> {
        let folder_pad = self.folder_pad.clone();
        Box::pin(async move {
            let md5 = folder_pad.write().reset_folder(operations.into_inner())?;
            Ok(md5)
        })
    }
}

struct FolderRevisionWSDataStream {
    conflict_controller: Arc<FolderConflictController>,
}

impl FolderRevisionWSDataStream {
    pub fn new(conflict_controller: FolderConflictController) -> Self {
        Self {
            conflict_controller: Arc::new(conflict_controller),
        }
    }
}

impl RevisionWSDataStream for FolderRevisionWSDataStream {
    fn receive_push_revision(&self, bytes: Bytes) -> BoxResultFuture<(), FlowyError> {
        let resolver = self.conflict_controller.clone();
        Box::pin(async move { resolver.receive_bytes(bytes).await })
    }

    fn receive_ack(&self, id: String, ty: ServerRevisionWSDataType) -> BoxResultFuture<(), FlowyError> {
        let resolver = self.conflict_controller.clone();
        Box::pin(async move { resolver.ack_revision(id, ty).await })
    }

    fn receive_new_user_connect(&self, _new_user: NewDocumentUser) -> BoxResultFuture<(), FlowyError> {
        // Do nothing by now, just a placeholder for future extension.
        Box::pin(async move { Ok(()) })
    }

    fn pull_revisions_in_range(&self, range: RevisionRange) -> BoxResultFuture<(), FlowyError> {
        let resolver = self.conflict_controller.clone();
        Box::pin(async move { resolver.send_revisions(range).await })
    }
}
