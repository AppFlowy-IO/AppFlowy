#![allow(unused_attributes)]
#![allow(unused_attributes)]
use crate::old_editor::queue::{EditDocumentQueue, EditorCommand, EditorCommandSender};
use crate::{errors::FlowyError, DocumentEditor, DocumentUser};
use bytes::Bytes;
use flowy_database::ConnectionPool;
use flowy_error::{internal_error, FlowyResult};
use flowy_http_model::document::DocumentPayloadPB;
use flowy_http_model::revision::Revision;
use flowy_http_model::ws_data::ServerRevisionWSData;
use flowy_revision::{
    RevisionCloudService, RevisionManager, RevisionMergeable, RevisionObjectDeserializer, RevisionObjectSerializer,
    RevisionWebSocket,
};
use flowy_sync::{errors::CollaborateResult, util::make_operations_from_revisions};
use lib_infra::async_trait::async_trait;
use lib_infra::future::FutureResult;
use lib_ot::core::{AttributeEntry, AttributeHashMap};
use lib_ot::{
    core::{DeltaOperation, Interval},
    text_delta::DeltaTextOperations,
};
use lib_ws::WSConnectState;
use std::any::Any;
use std::sync::Arc;
use tokio::sync::{mpsc, oneshot};

pub struct DeltaDocumentEditor {
    pub doc_id: String,
    #[allow(dead_code)]
    rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
    #[cfg(feature = "sync")]
    ws_manager: Arc<flowy_revision::RevisionWebSocketManager>,
    edit_cmd_tx: EditorCommandSender,
}

impl DeltaDocumentEditor {
    #[allow(unused_variables)]
    pub(crate) async fn new(
        doc_id: &str,
        user: Arc<dyn DocumentUser>,
        mut rev_manager: RevisionManager<Arc<ConnectionPool>>,
        rev_web_socket: Arc<dyn RevisionWebSocket>,
        cloud_service: Arc<dyn RevisionCloudService>,
    ) -> FlowyResult<Arc<Self>> {
        let document = rev_manager
            .initialize::<DeltaDocumentRevisionSerde>(Some(cloud_service))
            .await?;
        let operations = DeltaTextOperations::from_bytes(&document.data)?;
        let rev_manager = Arc::new(rev_manager);
        let doc_id = doc_id.to_string();
        let user_id = user.user_id()?;

        let edit_cmd_tx = spawn_edit_queue(user, rev_manager.clone(), operations);
        #[cfg(feature = "sync")]
        let ws_manager = crate::old_editor::web_socket::make_document_ws_manager(
            doc_id.clone(),
            user_id.clone(),
            edit_cmd_tx.clone(),
            rev_manager.clone(),
            rev_web_socket,
        )
        .await;
        let editor = Arc::new(Self {
            doc_id,
            rev_manager,
            #[cfg(feature = "sync")]
            ws_manager,
            edit_cmd_tx,
        });
        Ok(editor)
    }

    pub async fn insert<T: ToString>(&self, index: usize, data: T) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<()>>();
        let msg = EditorCommand::Insert {
            index,
            data: data.to_string(),
            ret,
        };
        let _ = self.edit_cmd_tx.send(msg).await;
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    pub async fn delete(&self, interval: Interval) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<()>>();
        let msg = EditorCommand::Delete { interval, ret };
        let _ = self.edit_cmd_tx.send(msg).await;
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    pub async fn format(&self, interval: Interval, attribute: AttributeEntry) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<()>>();
        let msg = EditorCommand::Format {
            interval,
            attribute,
            ret,
        };
        let _ = self.edit_cmd_tx.send(msg).await;
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    pub async fn replace<T: ToString>(&self, interval: Interval, data: T) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<()>>();
        let msg = EditorCommand::Replace {
            interval,
            data: data.to_string(),
            ret,
        };
        let _ = self.edit_cmd_tx.send(msg).await;
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    pub async fn can_undo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = EditorCommand::CanUndo { ret };
        let _ = self.edit_cmd_tx.send(msg).await;
        rx.await.unwrap_or(false)
    }

    pub async fn can_redo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = EditorCommand::CanRedo { ret };
        let _ = self.edit_cmd_tx.send(msg).await;
        rx.await.unwrap_or(false)
    }

    pub async fn undo(&self) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel();
        let msg = EditorCommand::Undo { ret };
        let _ = self.edit_cmd_tx.send(msg).await;
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    pub async fn redo(&self) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel();
        let msg = EditorCommand::Redo { ret };
        let _ = self.edit_cmd_tx.send(msg).await;
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }
}

#[async_trait]
impl DocumentEditor for Arc<DeltaDocumentEditor> {
    async fn close(&self) {
        #[cfg(feature = "sync")]
        self.ws_manager.stop();
    }

    fn export(&self) -> FutureResult<String, FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<String>>();
        let msg = EditorCommand::GetOperationsString { ret };
        let edit_cmd_tx = self.edit_cmd_tx.clone();
        FutureResult::new(async move {
            let _ = edit_cmd_tx.send(msg).await;
            let json = rx.await.map_err(internal_error)??;
            Ok(json)
        })
    }

    fn duplicate(&self) -> FutureResult<String, FlowyError> {
        self.export()
    }

    #[allow(unused_variables)]
    fn receive_ws_data(&self, data: ServerRevisionWSData) -> FutureResult<(), FlowyError> {
        let cloned_self = self.clone();
        FutureResult::new(async move {
            #[cfg(feature = "sync")]
            let _ = cloned_self.ws_manager.receive_ws_data(data).await?;

            Ok(())
        })
    }

    #[allow(unused_variables)]
    fn receive_ws_state(&self, state: &WSConnectState) {
        #[cfg(feature = "sync")]
        self.ws_manager.connect_state_changed(state.clone());
    }

    fn compose_local_operations(&self, data: Bytes) -> FutureResult<(), FlowyError> {
        let edit_cmd_tx = self.edit_cmd_tx.clone();
        FutureResult::new(async move {
            let operations = DeltaTextOperations::from_bytes(&data)?;
            let (ret, rx) = oneshot::channel::<CollaborateResult<()>>();
            let msg = EditorCommand::ComposeLocalOperations { operations, ret };

            let _ = edit_cmd_tx.send(msg).await;
            let _ = rx.await.map_err(internal_error)??;
            Ok(())
        })
    }

    fn as_any(&self) -> &dyn Any {
        self
    }
}
impl std::ops::Drop for DeltaDocumentEditor {
    fn drop(&mut self) {
        tracing::trace!("{} DocumentEditor was dropped", self.doc_id)
    }
}

// The edit queue will exit after the EditorCommandSender was dropped.
fn spawn_edit_queue(
    user: Arc<dyn DocumentUser>,
    rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
    delta: DeltaTextOperations,
) -> EditorCommandSender {
    let (sender, receiver) = mpsc::channel(1000);
    let edit_queue = EditDocumentQueue::new(user, rev_manager, delta, receiver);
    // We can use tokio::task::spawn_local here by using tokio::spawn_blocking.
    // https://github.com/tokio-rs/tokio/issues/2095
    // tokio::task::spawn_blocking(move || {
    //     let rt = tokio::runtime::Handle::current();
    //     rt.block_on(async {
    //         let local = tokio::task::LocalSet::new();
    //         local.run_until(edit_queue.run()).await;
    //     });
    // });
    tokio::spawn(edit_queue.run());
    sender
}

#[cfg(feature = "flowy_unit_test")]
impl DeltaDocumentEditor {
    pub async fn document_operations(&self) -> FlowyResult<DeltaTextOperations> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<DeltaTextOperations>>();
        let msg = EditorCommand::GetOperations { ret };
        let _ = self.edit_cmd_tx.send(msg).await;
        let delta = rx.await.map_err(internal_error)??;
        Ok(delta)
    }

    pub fn rev_manager(&self) -> Arc<RevisionManager<Arc<ConnectionPool>>> {
        self.rev_manager.clone()
    }
}

pub struct DeltaDocumentRevisionSerde();
impl RevisionObjectDeserializer for DeltaDocumentRevisionSerde {
    type Output = DocumentPayloadPB;

    fn deserialize_revisions(object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let (base_rev_id, rev_id) = revisions.last().unwrap().pair_rev_id();
        let mut delta = make_operations_from_revisions(revisions)?;
        correct_delta(&mut delta);

        Result::<DocumentPayloadPB, FlowyError>::Ok(DocumentPayloadPB {
            doc_id: object_id.to_owned(),
            data: delta.json_bytes().to_vec(),
            rev_id,
            base_rev_id,
        })
    }
}

impl RevisionObjectSerializer for DeltaDocumentRevisionSerde {
    fn combine_revisions(revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let operations = make_operations_from_revisions::<AttributeHashMap>(revisions)?;
        Ok(operations.json_bytes())
    }
}

pub(crate) struct DeltaDocumentRevisionMergeable();
impl RevisionMergeable for DeltaDocumentRevisionMergeable {
    fn combine_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        DeltaDocumentRevisionSerde::combine_revisions(revisions)
    }
}

// quill-editor requires the delta should end with '\n' and only contains the
// insert operation. The function, correct_delta maybe be removed in the future.
fn correct_delta(delta: &mut DeltaTextOperations) {
    if let Some(op) = delta.ops.last() {
        let op_data = op.get_data();
        if !op_data.ends_with('\n') {
            tracing::warn!("The document must end with newline. Correcting it by inserting newline op");
            delta.ops.push(DeltaOperation::Insert("\n".into()));
        }
    }

    if let Some(op) = delta.ops.iter().find(|op| !op.is_insert()) {
        tracing::warn!("The document can only contains insert operations, but found {:?}", op);
        delta.ops.retain(|op| op.is_insert());
    }
}
