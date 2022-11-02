use crate::old_editor::queue::{EditorCommand, EditorCommandSender, TextTransformOperations};
use crate::TEXT_BLOCK_SYNC_INTERVAL_IN_MILLIS;
use bytes::Bytes;
use flowy_database::ConnectionPool;
use flowy_error::{internal_error, FlowyError, FlowyResult};
use flowy_revision::*;
use flowy_sync::entities::revision::Revision;
use flowy_sync::util::make_operations_from_revisions;
use flowy_sync::{
    entities::{
        revision::RevisionRange,
        ws_data::{ClientRevisionWSData, NewDocumentUser, ServerRevisionWSDataType},
    },
    errors::CollaborateResult,
};
use lib_infra::future::{BoxResultFuture, FutureResult};
use lib_ot::text_delta::DeltaTextOperations;
use lib_ws::WSConnectState;
use std::{sync::Arc, time::Duration};
use tokio::sync::{broadcast, oneshot};

#[derive(Clone)]
pub struct DeltaDocumentResolveOperations(pub DeltaTextOperations);

impl OperationsDeserializer<DeltaDocumentResolveOperations> for DeltaDocumentResolveOperations {
    fn deserialize_revisions(revisions: Vec<Revision>) -> FlowyResult<DeltaDocumentResolveOperations> {
        Ok(DeltaDocumentResolveOperations(make_operations_from_revisions(
            revisions,
        )?))
    }
}

impl OperationsSerializer for DeltaDocumentResolveOperations {
    fn serialize_operations(&self) -> Bytes {
        self.0.json_bytes()
    }
}

impl DeltaDocumentResolveOperations {
    pub fn into_inner(self) -> DeltaTextOperations {
        self.0
    }
}

pub type DocumentConflictController = ConflictController<DeltaDocumentResolveOperations, Arc<ConnectionPool>>;

#[allow(dead_code)]
pub(crate) async fn make_document_ws_manager(
    doc_id: String,
    user_id: String,
    edit_cmd_tx: EditorCommandSender,
    rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
    rev_web_socket: Arc<dyn RevisionWebSocket>,
) -> Arc<RevisionWebSocketManager> {
    let ws_data_provider = Arc::new(WSDataProvider::new(&doc_id, Arc::new(rev_manager.clone())));
    let resolver = Arc::new(DocumentConflictResolver { edit_cmd_tx });
    let conflict_controller =
        DocumentConflictController::new(&user_id, resolver, Arc::new(ws_data_provider.clone()), rev_manager);
    let ws_data_stream = Arc::new(DocumentRevisionWSDataStream::new(conflict_controller));
    let ws_data_sink = Arc::new(DocumentWSDataSink(ws_data_provider));
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

pub(crate) struct DocumentRevisionWSDataStream {
    conflict_controller: Arc<DocumentConflictController>,
}

impl DocumentRevisionWSDataStream {
    #[allow(dead_code)]
    pub fn new(conflict_controller: DocumentConflictController) -> Self {
        Self {
            conflict_controller: Arc::new(conflict_controller),
        }
    }
}

impl RevisionWSDataStream for DocumentRevisionWSDataStream {
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

pub(crate) struct DocumentWSDataSink(pub(crate) Arc<WSDataProvider>);
impl RevisionWebSocketSink for DocumentWSDataSink {
    fn next(&self) -> FutureResult<Option<ClientRevisionWSData>, FlowyError> {
        let sink_provider = self.0.clone();
        FutureResult::new(async move { sink_provider.next().await })
    }
}

struct DocumentConflictResolver {
    edit_cmd_tx: EditorCommandSender,
}

impl ConflictResolver<DeltaDocumentResolveOperations> for DocumentConflictResolver {
    fn compose_operations(
        &self,
        operations: DeltaDocumentResolveOperations,
    ) -> BoxResultFuture<RevisionMD5, FlowyError> {
        let tx = self.edit_cmd_tx.clone();
        let operations = operations.into_inner();
        Box::pin(async move {
            let (ret, rx) = oneshot::channel();
            tx.send(EditorCommand::ComposeRemoteOperation {
                client_operations: operations,
                ret,
            })
            .await
            .map_err(internal_error)?;
            let md5 = rx
                .await
                .map_err(|e| FlowyError::internal().context(format!("Compose operations failed: {}", e)))??;
            Ok(md5)
        })
    }

    fn transform_operations(
        &self,
        operations: DeltaDocumentResolveOperations,
    ) -> BoxResultFuture<TransformOperations<DeltaDocumentResolveOperations>, FlowyError> {
        let tx = self.edit_cmd_tx.clone();
        let operations = operations.into_inner();
        Box::pin(async move {
            let (ret, rx) = oneshot::channel::<CollaborateResult<TextTransformOperations>>();
            tx.send(EditorCommand::TransformOperations { operations, ret })
                .await
                .map_err(internal_error)?;
            let transformed_operations = rx
                .await
                .map_err(|e| FlowyError::internal().context(format!("Transform operations failed: {}", e)))??;
            Ok(transformed_operations)
        })
    }

    fn reset_operations(&self, operations: DeltaDocumentResolveOperations) -> BoxResultFuture<RevisionMD5, FlowyError> {
        let tx = self.edit_cmd_tx.clone();
        let operations = operations.into_inner();
        Box::pin(async move {
            let (ret, rx) = oneshot::channel();
            let _ = tx
                .send(EditorCommand::ResetOperations { operations, ret })
                .await
                .map_err(internal_error)?;
            let md5 = rx
                .await
                .map_err(|e| FlowyError::internal().context(format!("Reset operations failed: {}", e)))??;
            Ok(md5)
        })
    }
}
