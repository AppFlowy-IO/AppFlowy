use crate::web_socket::EditorCommandSender;
use crate::{
    errors::FlowyError,
    queue::{EditBlockQueue, EditorCommand},
    TextBlockUser,
};
use bytes::Bytes;
use flowy_error::{internal_error, FlowyResult};
use flowy_revision::{RevisionCloudService, RevisionManager, RevisionObjectBuilder, RevisionWebSocket};
use flowy_sync::entities::ws_data::ServerRevisionWSData;
use flowy_sync::{
    entities::{revision::Revision, text_block_info::TextBlockInfo},
    errors::CollaborateResult,
    util::make_delta_from_revisions,
};
use lib_ot::{
    core::{Interval, Operation},
    rich_text::{RichTextAttribute, RichTextDelta},
};
use lib_ws::WSConnectState;
use std::sync::Arc;
use tokio::sync::{mpsc, oneshot};

pub struct ClientTextBlockEditor {
    pub doc_id: String,
    #[allow(dead_code)]
    rev_manager: Arc<RevisionManager>,
    #[cfg(feature = "sync")]
    ws_manager: Arc<RevisionWebSocketManager>,
    edit_cmd_tx: EditorCommandSender,
}

impl ClientTextBlockEditor {
    pub(crate) async fn new(
        doc_id: &str,
        user: Arc<dyn TextBlockUser>,
        mut rev_manager: RevisionManager,
        _rev_web_socket: Arc<dyn RevisionWebSocket>,
        cloud_service: Arc<dyn RevisionCloudService>,
    ) -> FlowyResult<Arc<Self>> {
        let document_info = rev_manager.load::<TextBlockInfoBuilder>(Some(cloud_service)).await?;
        let delta = document_info.delta()?;
        let rev_manager = Arc::new(rev_manager);
        let doc_id = doc_id.to_string();
        let _user_id = user.user_id()?;

        let edit_cmd_tx = spawn_edit_queue(user, rev_manager.clone(), delta);
        #[cfg(feature = "sync")]
        let ws_manager = make_block_ws_manager(
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

    pub async fn format(&self, interval: Interval, attribute: RichTextAttribute) -> Result<(), FlowyError> {
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

    pub async fn delta_str(&self) -> FlowyResult<String> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<String>>();
        let msg = EditorCommand::ReadDeltaStr { ret };
        let _ = self.edit_cmd_tx.send(msg).await;
        let json = rx.await.map_err(internal_error)??;
        Ok(json)
    }

    #[tracing::instrument(level = "trace", skip(self, data), err)]
    pub(crate) async fn compose_local_delta(&self, data: Bytes) -> Result<(), FlowyError> {
        let delta = RichTextDelta::from_bytes(&data)?;
        let (ret, rx) = oneshot::channel::<CollaborateResult<()>>();
        let msg = EditorCommand::ComposeLocalDelta {
            delta: delta.clone(),
            ret,
        };
        let _ = self.edit_cmd_tx.send(msg).await;
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    #[cfg(feature = "sync")]
    pub fn stop(&self) {
        self.ws_manager.stop();
    }

    #[cfg(not(feature = "sync"))]
    pub fn stop(&self) {}

    #[cfg(feature = "sync")]
    pub(crate) async fn receive_ws_data(&self, data: ServerRevisionWSData) -> Result<(), FlowyError> {
        self.ws_manager.receive_ws_data(data).await
    }
    #[cfg(not(feature = "sync"))]
    pub(crate) async fn receive_ws_data(&self, _data: ServerRevisionWSData) -> Result<(), FlowyError> {
        Ok(())
    }

    #[cfg(feature = "sync")]
    pub(crate) fn receive_ws_state(&self, state: &WSConnectState) {
        self.ws_manager.connect_state_changed(state.clone());
    }
    #[cfg(not(feature = "sync"))]
    pub(crate) fn receive_ws_state(&self, _state: &WSConnectState) {}
}

impl std::ops::Drop for ClientTextBlockEditor {
    fn drop(&mut self) {
        tracing::trace!("{} ClientBlockEditor was dropped", self.doc_id)
    }
}

// The edit queue will exit after the EditorCommandSender was dropped.
fn spawn_edit_queue(
    user: Arc<dyn TextBlockUser>,
    rev_manager: Arc<RevisionManager>,
    delta: RichTextDelta,
) -> EditorCommandSender {
    let (sender, receiver) = mpsc::channel(1000);
    let edit_queue = EditBlockQueue::new(user, rev_manager, delta, receiver);
    tokio::spawn(edit_queue.run());
    sender
}

#[cfg(feature = "flowy_unit_test")]
impl ClientTextBlockEditor {
    pub async fn text_block_delta(&self) -> FlowyResult<RichTextDelta> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<RichTextDelta>>();
        let msg = EditorCommand::ReadDelta { ret };
        let _ = self.edit_cmd_tx.send(msg).await;
        let delta = rx.await.map_err(internal_error)??;
        Ok(delta)
    }

    pub fn rev_manager(&self) -> Arc<RevisionManager> {
        self.rev_manager.clone()
    }
}

struct TextBlockInfoBuilder();
impl RevisionObjectBuilder for TextBlockInfoBuilder {
    type Output = TextBlockInfo;

    fn build_object(object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let (base_rev_id, rev_id) = revisions.last().unwrap().pair_rev_id();
        let mut delta = make_delta_from_revisions(revisions)?;
        correct_delta(&mut delta);

        Result::<TextBlockInfo, FlowyError>::Ok(TextBlockInfo {
            block_id: object_id.to_owned(),
            text: delta.to_delta_str(),
            rev_id,
            base_rev_id,
        })
    }
}

// quill-editor requires the delta should end with '\n' and only contains the
// insert operation. The function, correct_delta maybe be removed in the future.
fn correct_delta(delta: &mut RichTextDelta) {
    if let Some(op) = delta.ops.last() {
        let op_data = op.get_data();
        if !op_data.ends_with('\n') {
            tracing::warn!("The document must end with newline. Correcting it by inserting newline op");
            delta.ops.push(Operation::Insert("\n".into()));
        }
    }

    if let Some(op) = delta.ops.iter().find(|op| !op.is_insert()) {
        tracing::warn!("The document can only contains insert operations, but found {:?}", op);
        delta.ops.retain(|op| op.is_insert());
    }
}
