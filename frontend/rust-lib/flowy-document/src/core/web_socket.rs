use crate::{
    core::{EditorCommand, SYNC_INTERVAL_IN_MILLIS},
    DocumentWSReceiver,
};
use async_trait::async_trait;
use bytes::Bytes;
use flowy_collaboration::{
    entities::{
        revision::RevisionRange,
        ws_data::{ClientRevisionWSData, NewDocumentUser, ServerRevisionWSData, ServerRevisionWSDataType},
    },
    errors::CollaborateResult,
};
use flowy_error::{internal_error, FlowyError};
use flowy_sync::*;
use lib_infra::future::{BoxResultFuture, FutureResult};
use lib_ot::{core::Delta, rich_text::RichTextAttributes};
use lib_ws::WSConnectState;
use std::{sync::Arc, time::Duration};
use tokio::sync::{
    broadcast,
    mpsc::{Receiver, Sender},
    oneshot,
};

pub(crate) type EditorCommandSender = Sender<EditorCommand>;
pub(crate) type EditorCommandReceiver = Receiver<EditorCommand>;

pub(crate) async fn make_document_ws_manager(
    doc_id: String,
    user_id: String,
    edit_cmd_tx: EditorCommandSender,
    rev_manager: Arc<RevisionManager>,
    web_socket: Arc<dyn RevisionWebSocket>,
) -> Arc<RevisionWebSocketManager> {
    let composite_sink_provider = Arc::new(CompositeWSSinkDataProvider::new(&doc_id, rev_manager.clone()));
    let resolve_target = Arc::new(DocumentRevisionResolveTarget { edit_cmd_tx });
    let resolver = RevisionConflictResolver::<RichTextAttributes>::new(
        &user_id,
        resolve_target,
        Arc::new(composite_sink_provider.clone()),
        rev_manager,
    );
    let ws_stream_consumer = Arc::new(DocumentWSSteamConsumerAdapter {
        resolver: Arc::new(resolver),
    });

    let sink_provider = Arc::new(DocumentWSSinkDataProviderAdapter(composite_sink_provider));
    let ping_duration = Duration::from_millis(SYNC_INTERVAL_IN_MILLIS);
    let ws_manager = Arc::new(RevisionWebSocketManager::new(
        &doc_id,
        web_socket,
        sink_provider,
        ws_stream_consumer,
        ping_duration,
    ));
    listen_document_ws_state(&user_id, &doc_id, ws_manager.scribe_state());
    ws_manager
}

fn listen_document_ws_state(_user_id: &str, _doc_id: &str, mut subscriber: broadcast::Receiver<WSConnectState>) {
    tokio::spawn(async move {
        while let Ok(state) = subscriber.recv().await {
            match state {
                WSConnectState::Init => {},
                WSConnectState::Connecting => {},
                WSConnectState::Connected => {},
                WSConnectState::Disconnected => {},
            }
        }
    });
}

pub(crate) struct DocumentWSSteamConsumerAdapter {
    resolver: Arc<RevisionConflictResolver<RichTextAttributes>>,
}

impl RevisionWSSteamConsumer for DocumentWSSteamConsumerAdapter {
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

pub(crate) struct DocumentWSSinkDataProviderAdapter(pub(crate) Arc<CompositeWSSinkDataProvider>);
impl RevisionWSSinkDataProvider for DocumentWSSinkDataProviderAdapter {
    fn next(&self) -> FutureResult<Option<ClientRevisionWSData>, FlowyError> {
        let sink_provider = self.0.clone();
        FutureResult::new(async move { sink_provider.next().await })
    }
}

struct DocumentRevisionResolveTarget {
    edit_cmd_tx: EditorCommandSender,
}

impl ResolverTarget<RichTextAttributes> for DocumentRevisionResolveTarget {
    fn compose_delta(&self, delta: Delta<RichTextAttributes>) -> BoxResultFuture<DeltaMD5, FlowyError> {
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
        delta: Delta<RichTextAttributes>,
    ) -> BoxResultFuture<flowy_sync::TransformDeltas<RichTextAttributes>, FlowyError> {
        let tx = self.edit_cmd_tx.clone();
        Box::pin(async move {
            let (ret, rx) = oneshot::channel::<CollaborateResult<TransformDeltas<RichTextAttributes>>>();
            tx.send(EditorCommand::TransformDelta { delta, ret })
                .await
                .map_err(internal_error)?;
            let transform_delta = rx
                .await
                .map_err(|e| FlowyError::internal().context(format!("TransformDelta failed: {}", e)))??;
            Ok(transform_delta)
        })
    }

    fn reset_delta(&self, delta: Delta<RichTextAttributes>) -> BoxResultFuture<DeltaMD5, FlowyError> {
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

//  RevisionWebSocketManager registers itself as a DocumentWSReceiver for each
//  opened document.
#[async_trait]
impl DocumentWSReceiver for RevisionWebSocketManager {
    #[tracing::instrument(level = "debug", skip(self, data), err)]
    async fn receive_ws_data(&self, data: ServerRevisionWSData) -> Result<(), FlowyError> {
        let _ = self.ws_passthrough_tx.send(data).await.map_err(|e| {
            let err_msg = format!("{} passthrough error: {}", self.object_id, e);
            FlowyError::internal().context(err_msg)
        })?;
        Ok(())
    }

    fn connect_state_changed(&self, state: WSConnectState) {
        match self.state_passthrough_tx.send(state) {
            Ok(_) => {},
            Err(e) => tracing::error!("{}", e),
        }
    }
}
