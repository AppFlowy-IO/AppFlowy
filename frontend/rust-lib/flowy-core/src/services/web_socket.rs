use crate::services::FOLDER_SYNC_INTERVAL_IN_MILLIS;
use bytes::Bytes;
use flowy_collaboration::{
    entities::{
        revision::RevisionRange,
        ws_data::{ClientRevisionWSData, NewDocumentUser, ServerRevisionWSDataType},
    },
    folder::FolderPad,
};
use flowy_error::FlowyError;
use flowy_sync::*;
use lib_infra::future::{BoxResultFuture, FutureResult};
use lib_ot::core::{Delta, OperationTransformable, PlainDelta, PlainTextAttributes};
use parking_lot::RwLock;
use std::{sync::Arc, time::Duration};

pub(crate) async fn make_folder_ws_manager(
    user_id: &str,
    folder_id: &str,
    rev_manager: Arc<RevisionManager>,
    web_socket: Arc<dyn RevisionWebSocket>,
    folder_pad: Arc<RwLock<FolderPad>>,
) -> Arc<RevisionWebSocketManager> {
    let composite_sink_provider = Arc::new(CompositeWSSinkDataProvider::new(folder_id, rev_manager.clone()));
    let resolve_target = Arc::new(FolderRevisionResolveTarget { folder_pad });
    let resolver = RevisionConflictResolver::<PlainTextAttributes>::new(
        user_id,
        resolve_target,
        Arc::new(composite_sink_provider.clone()),
        rev_manager,
    );

    let ws_stream_consumer = Arc::new(FolderWSStreamConsumerAdapter {
        resolver: Arc::new(resolver),
    });

    let sink_provider = Arc::new(FolderWSSinkDataProviderAdapter(composite_sink_provider));
    let ping_duration = Duration::from_millis(FOLDER_SYNC_INTERVAL_IN_MILLIS);
    Arc::new(RevisionWebSocketManager::new(
        "Folder",
        folder_id,
        web_socket,
        sink_provider,
        ws_stream_consumer,
        ping_duration,
    ))
}

pub(crate) struct FolderWSSinkDataProviderAdapter(Arc<CompositeWSSinkDataProvider>);
impl RevisionWSSinkDataProvider for FolderWSSinkDataProviderAdapter {
    fn next(&self) -> FutureResult<Option<ClientRevisionWSData>, FlowyError> {
        let sink_provider = self.0.clone();
        FutureResult::new(async move { sink_provider.next().await })
    }
}

struct FolderRevisionResolveTarget {
    folder_pad: Arc<RwLock<FolderPad>>,
}

impl ResolverTarget<PlainTextAttributes> for FolderRevisionResolveTarget {
    fn compose_delta(&self, delta: Delta<PlainTextAttributes>) -> BoxResultFuture<DeltaMD5, FlowyError> {
        let folder_pad = self.folder_pad.clone();
        Box::pin(async move {
            let md5 = folder_pad.write().compose_remote_delta(delta)?;
            Ok(md5)
        })
    }

    fn transform_delta(
        &self,
        delta: Delta<PlainTextAttributes>,
    ) -> BoxResultFuture<TransformDeltas<PlainTextAttributes>, FlowyError> {
        let folder_pad = self.folder_pad.clone();
        Box::pin(async move {
            let read_guard = folder_pad.read();
            let mut server_prime: Option<PlainDelta> = None;
            let client_prime: PlainDelta;
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

    fn reset_delta(&self, delta: Delta<PlainTextAttributes>) -> BoxResultFuture<DeltaMD5, FlowyError> {
        let folder_pad = self.folder_pad.clone();
        Box::pin(async move {
            let md5 = folder_pad.write().reset_folder(delta)?;
            Ok(md5)
        })
    }
}

struct FolderWSStreamConsumerAdapter {
    resolver: Arc<RevisionConflictResolver<PlainTextAttributes>>,
}

impl RevisionWSSteamConsumer for FolderWSStreamConsumerAdapter {
    fn receive_push_revision(&self, bytes: Bytes) -> BoxResultFuture<(), FlowyError> {
        let resolver = self.resolver.clone();
        Box::pin(async move { resolver.receive_bytes(bytes).await })
    }

    fn receive_ack(&self, id: String, ty: ServerRevisionWSDataType) -> BoxResultFuture<(), FlowyError> {
        let resolver = self.resolver.clone();
        Box::pin(async move { resolver.ack_revision(id, ty).await })
    }

    fn receive_new_user_connect(&self, _new_user: NewDocumentUser) -> BoxResultFuture<(), FlowyError> {
        // Do nothing by now, just a placeholder for future extension.
        Box::pin(async move { Ok(()) })
    }

    fn pull_revisions_in_range(&self, range: RevisionRange) -> BoxResultFuture<(), FlowyError> {
        let resolver = self.resolver.clone();
        Box::pin(async move { resolver.send_revisions(range).await })
    }
}
