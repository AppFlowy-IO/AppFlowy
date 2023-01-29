use crate::old_editor::web_socket::DeltaDocumentResolveOperations;
use crate::DocumentUser;
use async_stream::stream;
use flowy_database::ConnectionPool;
use flowy_error::FlowyError;
use flowy_revision::{RevisionMD5, RevisionManager, TransformOperations};
use flowy_sync::{
    client_document::{history::UndoResult, ClientDocument},
    errors::CollaborateError,
};
use futures::stream::StreamExt;
use lib_ot::core::AttributeEntry;
use lib_ot::{
    core::{Interval, OperationTransform},
    text_delta::DeltaTextOperations,
};
use std::sync::Arc;
use tokio::sync::mpsc::{Receiver, Sender};
use tokio::sync::{oneshot, RwLock};

// The EditorCommandQueue executes each command that will alter the document in
// serial.
pub(crate) struct EditDocumentQueue {
    document: Arc<RwLock<ClientDocument>>,
    #[allow(dead_code)]
    user: Arc<dyn DocumentUser>,
    rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
    receiver: Option<EditorCommandReceiver>,
}

impl EditDocumentQueue {
    pub(crate) fn new(
        user: Arc<dyn DocumentUser>,
        rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
        operations: DeltaTextOperations,
        receiver: EditorCommandReceiver,
    ) -> Self {
        let document = Arc::new(RwLock::new(ClientDocument::from_operations(operations)));
        Self {
            document,
            user,
            rev_manager,
            receiver: Some(receiver),
        }
    }

    pub(crate) async fn run(mut self) {
        let mut receiver = self.receiver.take().expect("Should only call once");
        let stream = stream! {
            loop {
                match receiver.recv().await {
                    Some(msg) => yield msg,
                    None => break,
                }
            }
        };
        stream
            .for_each(|command| async {
                match self.handle_command(command).await {
                    Ok(_) => {}
                    Err(e) => tracing::debug!("[EditCommandQueue]: {}", e),
                }
            })
            .await;
    }

    #[tracing::instrument(level = "trace", skip(self), err)]
    async fn handle_command(&self, command: EditorCommand) -> Result<(), FlowyError> {
        match command {
            EditorCommand::ComposeLocalOperations { operations, ret } => {
                let mut document = self.document.write().await;
                document.compose_operations(operations.clone())?;
                let md5 = document.document_md5();
                drop(document);
                let _ = self.save_local_operations(operations, md5).await?;
                let _ = ret.send(Ok(()));
            }
            EditorCommand::ComposeRemoteOperation { client_operations, ret } => {
                let mut document = self.document.write().await;
                document.compose_operations(client_operations.clone())?;
                let md5 = document.document_md5();
                drop(document);
                let _ = ret.send(Ok(md5.into()));
            }
            EditorCommand::ResetOperations { operations, ret } => {
                let mut document = self.document.write().await;
                document.set_operations(operations);
                let md5 = document.document_md5();
                drop(document);
                let _ = ret.send(Ok(md5.into()));
            }
            EditorCommand::TransformOperations { operations, ret } => {
                let f = || async {
                    let read_guard = self.document.read().await;
                    let mut server_operations: Option<DeltaDocumentResolveOperations> = None;
                    let client_operations: DeltaTextOperations;

                    if read_guard.is_empty() {
                        // Do nothing
                        client_operations = operations;
                    } else {
                        let (s_prime, c_prime) = read_guard.get_operations().transform(&operations)?;
                        client_operations = c_prime;
                        server_operations = Some(DeltaDocumentResolveOperations(s_prime));
                    }
                    drop(read_guard);
                    Ok::<TextTransformOperations, CollaborateError>(TransformOperations {
                        client_operations: DeltaDocumentResolveOperations(client_operations),
                        server_operations,
                    })
                };
                let _ = ret.send(f().await);
            }
            EditorCommand::Insert { index, data, ret } => {
                let mut write_guard = self.document.write().await;
                let operations = write_guard.insert(index, data)?;
                let md5 = write_guard.document_md5();
                let _ = self.save_local_operations(operations, md5).await?;
                let _ = ret.send(Ok(()));
            }
            EditorCommand::Delete { interval, ret } => {
                let mut write_guard = self.document.write().await;
                let operations = write_guard.delete(interval)?;
                let md5 = write_guard.document_md5();
                let _ = self.save_local_operations(operations, md5).await?;
                let _ = ret.send(Ok(()));
            }
            EditorCommand::Format {
                interval,
                attribute,
                ret,
            } => {
                let mut write_guard = self.document.write().await;
                let operations = write_guard.format(interval, attribute)?;
                let md5 = write_guard.document_md5();
                let _ = self.save_local_operations(operations, md5).await?;
                let _ = ret.send(Ok(()));
            }
            EditorCommand::Replace { interval, data, ret } => {
                let mut write_guard = self.document.write().await;
                let operations = write_guard.replace(interval, data)?;
                let md5 = write_guard.document_md5();
                let _ = self.save_local_operations(operations, md5).await?;
                let _ = ret.send(Ok(()));
            }
            EditorCommand::CanUndo { ret } => {
                let _ = ret.send(self.document.read().await.can_undo());
            }
            EditorCommand::CanRedo { ret } => {
                let _ = ret.send(self.document.read().await.can_redo());
            }
            EditorCommand::Undo { ret } => {
                let mut write_guard = self.document.write().await;
                let UndoResult { operations } = write_guard.undo()?;
                let md5 = write_guard.document_md5();
                let _ = self.save_local_operations(operations, md5).await?;
                let _ = ret.send(Ok(()));
            }
            EditorCommand::Redo { ret } => {
                let mut write_guard = self.document.write().await;
                let UndoResult { operations } = write_guard.redo()?;
                let md5 = write_guard.document_md5();
                let _ = self.save_local_operations(operations, md5).await?;
                let _ = ret.send(Ok(()));
            }
            EditorCommand::GetOperationsString { ret } => {
                let data = self.document.read().await.get_operations_json();
                let _ = ret.send(Ok(data));
            }
            EditorCommand::GetOperations { ret } => {
                let operations = self.document.read().await.get_operations().clone();
                let _ = ret.send(Ok(operations));
            }
        }
        Ok(())
    }

    async fn save_local_operations(&self, operations: DeltaTextOperations, md5: String) -> Result<i64, FlowyError> {
        let bytes = operations.json_bytes();
        let rev_id = self.rev_manager.add_local_revision(bytes, md5).await?;
        Ok(rev_id)
    }
}

pub type TextTransformOperations = TransformOperations<DeltaDocumentResolveOperations>;
pub(crate) type EditorCommandSender = Sender<EditorCommand>;
pub(crate) type EditorCommandReceiver = Receiver<EditorCommand>;
pub(crate) type Ret<T> = oneshot::Sender<Result<T, CollaborateError>>;

pub(crate) enum EditorCommand {
    ComposeLocalOperations {
        operations: DeltaTextOperations,
        ret: Ret<()>,
    },
    ComposeRemoteOperation {
        client_operations: DeltaTextOperations,
        ret: Ret<RevisionMD5>,
    },
    ResetOperations {
        operations: DeltaTextOperations,
        ret: Ret<RevisionMD5>,
    },
    TransformOperations {
        operations: DeltaTextOperations,
        ret: Ret<TextTransformOperations>,
    },
    Insert {
        index: usize,
        data: String,
        ret: Ret<()>,
    },
    Delete {
        interval: Interval,
        ret: Ret<()>,
    },
    Format {
        interval: Interval,
        attribute: AttributeEntry,
        ret: Ret<()>,
    },
    Replace {
        interval: Interval,
        data: String,
        ret: Ret<()>,
    },
    CanUndo {
        ret: oneshot::Sender<bool>,
    },
    CanRedo {
        ret: oneshot::Sender<bool>,
    },
    Undo {
        ret: Ret<()>,
    },
    Redo {
        ret: Ret<()>,
    },
    GetOperationsString {
        ret: Ret<String>,
    },
    #[allow(dead_code)]
    GetOperations {
        ret: Ret<DeltaTextOperations>,
    },
}

impl std::fmt::Debug for EditorCommand {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        let s = match self {
            EditorCommand::ComposeLocalOperations { .. } => "ComposeLocalOperations",
            EditorCommand::ComposeRemoteOperation { .. } => "ComposeRemoteOperation",
            EditorCommand::ResetOperations { .. } => "ResetOperations",
            EditorCommand::TransformOperations { .. } => "TransformOperations",
            EditorCommand::Insert { .. } => "Insert",
            EditorCommand::Delete { .. } => "Delete",
            EditorCommand::Format { .. } => "Format",
            EditorCommand::Replace { .. } => "Replace",
            EditorCommand::CanUndo { .. } => "CanUndo",
            EditorCommand::CanRedo { .. } => "CanRedo",
            EditorCommand::Undo { .. } => "Undo",
            EditorCommand::Redo { .. } => "Redo",
            EditorCommand::GetOperationsString { .. } => "StringifyOperations",
            EditorCommand::GetOperations { .. } => "ReadOperations",
        };
        f.write_str(s)
    }
}
