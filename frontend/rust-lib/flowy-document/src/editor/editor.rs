use crate::editor::document::{Document, DocumentRevisionSerde};
use crate::editor::queue::{Command, CommandSender, DocumentQueue};
use crate::{DocumentEditor, DocumentUser};
use bytes::Bytes;
use flowy_error::{internal_error, FlowyError, FlowyResult};
use flowy_revision::{RevisionCloudService, RevisionManager};
use flowy_sync::entities::ws_data::ServerRevisionWSData;
use lib_infra::future::FutureResult;
use lib_ot::core::Transaction;
use lib_ws::WSConnectState;
use std::any::Any;
use std::sync::Arc;
use tokio::sync::{mpsc, oneshot};

pub struct AppFlowyDocumentEditor {
    #[allow(dead_code)]
    doc_id: String,
    command_sender: CommandSender,
}

impl AppFlowyDocumentEditor {
    pub async fn new(
        doc_id: &str,
        user: Arc<dyn DocumentUser>,
        mut rev_manager: RevisionManager,
        cloud_service: Arc<dyn RevisionCloudService>,
    ) -> FlowyResult<Arc<Self>> {
        let document = rev_manager.load::<DocumentRevisionSerde>(Some(cloud_service)).await?;
        let rev_manager = Arc::new(rev_manager);
        let command_sender = spawn_edit_queue(user, rev_manager, document);
        let doc_id = doc_id.to_string();
        let editor = Arc::new(Self { doc_id, command_sender });
        Ok(editor)
    }

    pub async fn apply_transaction(&self, transaction: Transaction) -> FlowyResult<()> {
        let (ret, rx) = oneshot::channel::<FlowyResult<()>>();
        let _ = self
            .command_sender
            .send(Command::ComposeTransaction { transaction, ret })
            .await;
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    pub async fn get_content(&self, pretty: bool) -> FlowyResult<String> {
        let (ret, rx) = oneshot::channel::<FlowyResult<String>>();
        let _ = self
            .command_sender
            .send(Command::GetDocumentContent { pretty, ret })
            .await;
        let content = rx.await.map_err(internal_error)??;
        Ok(content)
    }
}

fn spawn_edit_queue(
    user: Arc<dyn DocumentUser>,
    rev_manager: Arc<RevisionManager>,
    document: Document,
) -> CommandSender {
    let (sender, receiver) = mpsc::channel(1000);
    let queue = DocumentQueue::new(user, rev_manager, document, receiver);
    tokio::spawn(queue.run());
    sender
}

impl DocumentEditor for Arc<AppFlowyDocumentEditor> {
    fn get_operations_str(&self) -> FutureResult<String, FlowyError> {
        todo!()
    }

    fn compose_local_operations(&self, _data: Bytes) -> FutureResult<(), FlowyError> {
        todo!()
    }

    fn close(&self) {
        todo!()
    }

    fn receive_ws_data(&self, _data: ServerRevisionWSData) -> FutureResult<(), FlowyError> {
        todo!()
    }

    fn receive_ws_state(&self, _state: &WSConnectState) {
        todo!()
    }

    fn as_any(&self) -> &dyn Any {
        self
    }
}
