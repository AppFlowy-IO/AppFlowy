use crate::services::FOLDER_SYNC_INTERVAL_IN_MILLIS;
use bytes::Bytes;
use flowy_error::FlowyError;
use flowy_revision::*;
use flowy_sync::{
    client_folder::FolderPad,
    entities::{
        revision::RevisionRange,
        ws_data::{ClientRevisionWSData, NewDocumentUser, ServerRevisionWSDataType},
    },
};
use lib_infra::future::{BoxResultFuture, FutureResult};
use lib_ot::core::{Delta, EmptyAttributes, OperationTransform};
use parking_lot::RwLock;
use std::{sync::Arc, time::Duration};

#[allow(dead_code)]
pub(crate) async fn make_folder_ws_manager(
    user_id: &str,
    folder_id: &str,
    rev_manager: Arc<RevisionManager>,
    web_socket: Arc<dyn RevisionWebSocket>,
    folder_pad: Arc<RwLock<FolderPad>>,
) -> Arc<RevisionWebSocketManager> {
    let ws_data_provider = Arc::new(WSDataProvider::new(folder_id, Arc::new(rev_manager.clone())));
    let resolver = Arc::new(FolderConflictResolver { folder_pad });
    let conflict_controller =
        ConflictController::<EmptyAttributes>::new(user_id, resolver, Arc::new(ws_data_provider.clone()), rev_manager);
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

impl ConflictResolver<EmptyAttributes> for FolderConflictResolver {
    fn compose_delta(&self, delta: Delta) -> BoxResultFuture<OperationsMD5, FlowyError> {
        let folder_pad = self.folder_pad.clone();
        Box::pin(async move {
            let md5 = folder_pad.write().compose_remote_delta(delta)?;
            Ok(md5)
        })
    }

    fn transform_delta(&self, delta: Delta) -> BoxResultFuture<TransformDeltas<EmptyAttributes>, FlowyError> {
        let folder_pad = self.folder_pad.clone();
        Box::pin(async move {
            let read_guard = folder_pad.read();
            let mut server_prime: Option<Delta> = None;
            let client_prime: Delta;
            if read_guard.is_empty() {
                // Do nothing
                client_prime = delta;
            } else {
                let (s_prime, c_prime) = read_guard.delta().transform(&delta)?;
                client_prime = c_prime;
                server_prime = Some(s_prime);
            }
            drop(read_guard);
            Ok(TransformDeltas {
                client_prime,
                server_prime,
            })
        })
    }

    fn reset_delta(&self, delta: Delta) -> BoxResultFuture<OperationsMD5, FlowyError> {
        let folder_pad = self.folder_pad.clone();
        Box::pin(async move {
            let md5 = folder_pad.write().reset_folder(delta)?;
            Ok(md5)
        })
    }
}

struct FolderRevisionWSDataStream {
    conflict_controller: Arc<PlainTextConflictController>,
}

impl FolderRevisionWSDataStream {
    pub fn new(conflict_controller: PlainTextConflictController) -> Self {
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
