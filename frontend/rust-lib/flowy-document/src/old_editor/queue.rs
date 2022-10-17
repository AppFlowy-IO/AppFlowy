use crate::old_editor::web_socket::{DocumentResolveOperations, EditorCommandReceiver};
use crate::DocumentUser;
use async_stream::stream;
use flowy_error::FlowyError;
use flowy_revision::{OperationsMD5, RevisionManager, TransformOperations};
use flowy_sync::{
    client_document::{history::UndoResult, ClientDocument},
    entities::revision::{RevId, Revision},
    errors::CollaborateError,
};
use futures::stream::StreamExt;
use lib_ot::core::AttributeEntry;
use lib_ot::{
    core::{Interval, OperationTransform},
    text_delta::TextOperations,
};
use std::sync::Arc;
use tokio::sync::{oneshot, RwLock};

// The EditorCommandQueue executes each command that will alter the document in
// serial.
pub(crate) struct EditDocumentQueue {
    document: Arc<RwLock<ClientDocument>>,
    user: Arc<dyn DocumentUser>,
    rev_manager: Arc<RevisionManager>,
    receiver: Option<EditorCommandReceiver>,
}

impl EditDocumentQueue {
    pub(crate) fn new(
        user: Arc<dyn DocumentUser>,
        rev_manager: Arc<RevisionManager>,
        operations: TextOperations,
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
                let _ = document.compose_operations(operations.clone())?;
                let md5 = document.md5();
                drop(document);
                let _ = self.save_local_operations(operations, md5).await?;
                let _ = ret.send(Ok(()));
            }
            EditorCommand::ComposeRemoteOperation { client_operations, ret } => {
                let mut document = self.document.write().await;
                let _ = document.compose_operations(client_operations.clone())?;
                let md5 = document.md5();
                drop(document);
                let _ = ret.send(Ok(md5));
            }
            EditorCommand::ResetOperations { operations, ret } => {
                let mut document = self.document.write().await;
                let _ = document.set_operations(operations);
                let md5 = document.md5();
                drop(document);
                let _ = ret.send(Ok(md5));
            }
            EditorCommand::TransformOperations { operations, ret } => {
                let f = || async {
                    let read_guard = self.document.read().await;
                    let mut server_operations: Option<DocumentResolveOperations> = None;
                    let client_operations: TextOperations;

                    if read_guard.is_empty() {
                        // Do nothing
                        client_operations = operations;
                    } else {
                        let (s_prime, c_prime) = read_guard.get_operations().transform(&operations)?;
                        client_operations = c_prime;
                        server_operations = Some(DocumentResolveOperations(s_prime));
                    }
                    drop(read_guard);
                    Ok::<TextTransformOperations, CollaborateError>(TransformOperations {
                        client_operations: DocumentResolveOperations(client_operations),
                        server_operations,
                    })
                };
                let _ = ret.send(f().await);
            }
            EditorCommand::Insert { index, data, ret } => {
                let mut write_guard = self.document.write().await;
                let operations = write_guard.insert(index, data)?;
                let md5 = write_guard.md5();
                let _ = self.save_local_operations(operations, md5).await?;
                let _ = ret.send(Ok(()));
            }
            EditorCommand::Delete { interval, ret } => {
                let mut write_guard = self.document.write().await;
                let operations = write_guard.delete(interval)?;
                let md5 = write_guard.md5();
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
                let md5 = write_guard.md5();
                let _ = self.save_local_operations(operations, md5).await?;
                let _ = ret.send(Ok(()));
            }
            EditorCommand::Replace { interval, data, ret } => {
                let mut write_guard = self.document.write().await;
                let operations = write_guard.replace(interval, data)?;
                let md5 = write_guard.md5();
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
                let md5 = write_guard.md5();
                let _ = self.save_local_operations(operations, md5).await?;
                let _ = ret.send(Ok(()));
            }
            EditorCommand::Redo { ret } => {
                let mut write_guard = self.document.write().await;
                let UndoResult { operations } = write_guard.redo()?;
                let md5 = write_guard.md5();
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

    async fn save_local_operations(&self, operations: TextOperations, md5: String) -> Result<RevId, FlowyError> {
        let bytes = operations.json_bytes();
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id_pair();
        let user_id = self.user.user_id()?;
        let revision = Revision::new(&self.rev_manager.object_id, base_rev_id, rev_id, bytes, &user_id, md5);
        let _ = self.rev_manager.add_local_revision(&revision).await?;
        Ok(rev_id.into())
    }
}

pub type TextTransformOperations = TransformOperations<DocumentResolveOperations>;

pub(crate) type Ret<T> = oneshot::Sender<Result<T, CollaborateError>>;

pub(crate) enum EditorCommand {
    ComposeLocalOperations {
        operations: TextOperations,
        ret: Ret<()>,
    },
    ComposeRemoteOperation {
        client_operations: TextOperations,
        ret: Ret<OperationsMD5>,
    },
    ResetOperations {
        operations: TextOperations,
        ret: Ret<OperationsMD5>,
    },
    TransformOperations {
        operations: TextOperations,
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
        ret: Ret<TextOperations>,
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
