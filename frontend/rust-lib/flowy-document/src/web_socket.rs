use crate::{queue::EditorCommand, DOCUMENT_SYNC_INTERVAL_IN_MILLIS};
use bytes::Bytes;
use flowy_collaboration::{
    entities::{
        revision::RevisionRange,
        ws_data::{ClientRevisionWSData, NewDocumentUser, ServerRevisionWSDataType},
    },
    errors::CollaborateResult,
};
use flowy_error::{internal_error, FlowyError};
use flowy_sync::*;
use lib_infra::future::{BoxResultFuture, FutureResult};
use lib_ot::rich_text::RichTextAttributes;
use lib_ot::rich_text::RichTextDelta;
use lib_ws::WSConnectState;
use std::{sync::Arc, time::Duration};
use tokio::sync::{
    broadcast,
    mpsc::{Receiver, Sender},
    oneshot,
};

pub(crate) type EditorCommandSender = Sender<EditorCommand>;
pub(crate) type EditorCommandReceiver = Receiver<EditorCommand>;

pub(crate) async fn make_block_ws_manager(
    doc_id: String,
    user_id: String,
    edit_cmd_tx: EditorCommandSender,
    rev_manager: Arc<RevisionManager>,
    rev_web_socket: Arc<dyn RevisionWebSocket>,
) -> Arc<RevisionWebSocketManager> {
    let ws_data_provider = Arc::new(WSDataProvider::new(&doc_id, Arc::new(rev_manager.clone())));
    let resolver = Arc::new(BlockConflictResolver { edit_cmd_tx });
    let conflict_controller =
        RichTextConflictController::new(&user_id, resolver, Arc::new(ws_data_provider.clone()), rev_manager);
    let ws_data_stream = Arc::new(BlockRevisionWSDataStream::new(conflict_controller));
    let ws_data_sink = Arc::new(BlockWSDataSink(ws_data_provider));
    let ping_duration = Duration::from_millis(DOCUMENT_SYNC_INTERVAL_IN_MILLIS);
    let ws_manager = Arc::new(RevisionWebSocketManager::new(
        "Block",
        &doc_id,
        rev_web_socket,
        ws_data_sink,
        ws_data_stream,
        ping_duration,
    ));
    listen_document_ws_state(&user_id, &doc_id, ws_manager.scribe_state());
    ws_manager
}

fn listen_document_ws_state(_user_id: &str, _doc_id: &str, mut subscriber: broadcast::Receiver<WSConnectState>) {
    tokio::spawn(async move {
        while let Ok(state) = subscriber.recv().await {
            match state {
                WSConnectState::Init => {}
                WSConnectState::Connecting => {}
                WSConnectState::Connected => {}
                WSConnectState::Disconnected => {}
            }
        }
    });
}

pub(crate) struct BlockRevisionWSDataStream {
    conflict_controller: Arc<RichTextConflictController>,
}

impl BlockRevisionWSDataStream {
    pub fn new(conflict_controller: RichTextConflictController) -> Self {
        Self {
            conflict_controller: Arc::new(conflict_controller),
        }
    }
}

impl RevisionWSDataStream for BlockRevisionWSDataStream {
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

pub(crate) struct BlockWSDataSink(pub(crate) Arc<WSDataProvider>);
impl RevisionWSDataIterator for BlockWSDataSink {
    fn next(&self) -> FutureResult<Option<ClientRevisionWSData>, FlowyError> {
        let sink_provider = self.0.clone();
        FutureResult::new(async move { sink_provider.next().await })
    }
}

struct BlockConflictResolver {
    edit_cmd_tx: EditorCommandSender,
}

impl ConflictResolver<RichTextAttributes> for BlockConflictResolver {
    fn compose_delta(&self, delta: RichTextDelta) -> BoxResultFuture<DeltaMD5, FlowyError> {
        let tx = self.edit_cmd_tx.clone();
        Box::pin(async move {
            let (ret, rx) = oneshot::channel();
            tx.send(EditorCommand::ComposeRemoteDelta {
                client_delta: delta,
                ret,
            })
            .await
            .map_err(internal_error)?;
            let md5 = rx.await.map_err(|e| {
                FlowyError::internal().context(format!("handle EditorCommand::ComposeRemoteDelta failed: {}", e))
            })??;
            Ok(md5)
        })
    }

    fn transform_delta(
        &self,
        delta: RichTextDelta,
    ) -> BoxResultFuture<flowy_sync::RichTextTransformDeltas, FlowyError> {
        let tx = self.edit_cmd_tx.clone();
        Box::pin(async move {
            let (ret, rx) = oneshot::channel::<CollaborateResult<RichTextTransformDeltas>>();
            tx.send(EditorCommand::TransformDelta { delta, ret })
                .await
                .map_err(internal_error)?;
            let transform_delta = rx
                .await
                .map_err(|e| FlowyError::internal().context(format!("TransformDelta failed: {}", e)))??;
            Ok(transform_delta)
        })
    }

    fn reset_delta(&self, delta: RichTextDelta) -> BoxResultFuture<DeltaMD5, FlowyError> {
        let tx = self.edit_cmd_tx.clone();
        Box::pin(async move {
            let (ret, rx) = oneshot::channel();
            let _ = tx
                .send(EditorCommand::ResetDelta { delta, ret })
                .await
                .map_err(internal_error)?;
            let md5 = rx.await.map_err(|e| {
                FlowyError::internal().context(format!("handle EditorCommand::OverrideDelta failed: {}", e))
            })??;
            Ok(md5)
        })
    }
}
