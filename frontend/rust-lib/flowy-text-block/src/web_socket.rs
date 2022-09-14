use crate::{queue::EditorCommand, TEXT_BLOCK_SYNC_INTERVAL_IN_MILLIS};
use bytes::Bytes;
use flowy_error::{internal_error, FlowyError};
use flowy_revision::*;
use flowy_sync::{
    entities::{
        revision::RevisionRange,
        ws_data::{ClientRevisionWSData, NewDocumentUser, ServerRevisionWSDataType},
    },
    errors::CollaborateResult,
};
use lib_infra::future::{BoxResultFuture, FutureResult};
use lib_ot::core::Attributes;

use lib_ot::text_delta::TextDelta;
use lib_ws::WSConnectState;
use std::{sync::Arc, time::Duration};
use tokio::sync::{
    broadcast,
    mpsc::{Receiver, Sender},
    oneshot,
};

pub(crate) type EditorCommandSender = Sender<EditorCommand>;
pub(crate) type EditorCommandReceiver = Receiver<EditorCommand>;

#[allow(dead_code)]
pub(crate) async fn make_block_ws_manager(
    doc_id: String,
    user_id: String,
    edit_cmd_tx: EditorCommandSender,
    rev_manager: Arc<RevisionManager>,
    rev_web_socket: Arc<dyn RevisionWebSocket>,
) -> Arc<RevisionWebSocketManager> {
    let ws_data_provider = Arc::new(WSDataProvider::new(&doc_id, Arc::new(rev_manager.clone())));
    let resolver = Arc::new(TextBlockConflictResolver { edit_cmd_tx });
    let conflict_controller =
        RichTextConflictController::new(&user_id, resolver, Arc::new(ws_data_provider.clone()), rev_manager);
    let ws_data_stream = Arc::new(TextBlockRevisionWSDataStream::new(conflict_controller));
    let ws_data_sink = Arc::new(TextBlockWSDataSink(ws_data_provider));
    let ping_duration = Duration::from_millis(TEXT_BLOCK_SYNC_INTERVAL_IN_MILLIS);
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

#[allow(dead_code)]
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

pub(crate) struct TextBlockRevisionWSDataStream {
    conflict_controller: Arc<RichTextConflictController>,
}

impl TextBlockRevisionWSDataStream {
    #[allow(dead_code)]
    pub fn new(conflict_controller: RichTextConflictController) -> Self {
        Self {
            conflict_controller: Arc::new(conflict_controller),
        }
    }
}

impl RevisionWSDataStream for TextBlockRevisionWSDataStream {
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

pub(crate) struct TextBlockWSDataSink(pub(crate) Arc<WSDataProvider>);
impl RevisionWebSocketSink for TextBlockWSDataSink {
    fn next(&self) -> FutureResult<Option<ClientRevisionWSData>, FlowyError> {
        let sink_provider = self.0.clone();
        FutureResult::new(async move { sink_provider.next().await })
    }
}

struct TextBlockConflictResolver {
    edit_cmd_tx: EditorCommandSender,
}

impl ConflictResolver<Attributes> for TextBlockConflictResolver {
    fn compose_delta(&self, delta: TextDelta) -> BoxResultFuture<DeltaMD5, FlowyError> {
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
        delta: TextDelta,
    ) -> BoxResultFuture<flowy_revision::RichTextTransformDeltas, FlowyError> {
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

    fn reset_delta(&self, delta: TextDelta) -> BoxResultFuture<DeltaMD5, FlowyError> {
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
