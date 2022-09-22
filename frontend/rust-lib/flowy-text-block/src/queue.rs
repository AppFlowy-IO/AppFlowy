use crate::web_socket::EditorCommandReceiver;
use crate::TextEditorUser;
use async_stream::stream;
use bytes::Bytes;
use flowy_error::{FlowyError, FlowyResult};
use flowy_revision::{OperationsMD5, RevisionCompactor, RevisionManager, RichTextTransformDeltas, TransformDeltas};
use flowy_sync::util::make_operations_from_revisions;
use flowy_sync::{
    client_document::{history::UndoResult, ClientDocument},
    entities::revision::{RevId, Revision},
    errors::CollaborateError,
};
use futures::stream::StreamExt;
use lib_ot::core::{AttributeEntry, AttributeHashMap};
use lib_ot::{
    core::{Interval, OperationTransform},
    text_delta::TextOperations,
};
use std::sync::Arc;
use tokio::sync::{oneshot, RwLock};

// The EditorCommandQueue executes each command that will alter the document in
// serial.
pub(crate) struct EditBlockQueue {
    document: Arc<RwLock<ClientDocument>>,
    user: Arc<dyn TextEditorUser>,
    rev_manager: Arc<RevisionManager>,
    receiver: Option<EditorCommandReceiver>,
}

impl EditBlockQueue {
    pub(crate) fn new(
        user: Arc<dyn TextEditorUser>,
        rev_manager: Arc<RevisionManager>,
        delta: TextOperations,
        receiver: EditorCommandReceiver,
    ) -> Self {
        let document = Arc::new(RwLock::new(ClientDocument::from_delta(delta)));
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
            EditorCommand::ComposeLocalDelta { delta, ret } => {
                let mut document = self.document.write().await;
                let _ = document.compose_delta(delta.clone())?;
                let md5 = document.md5();
                drop(document);
                let _ = self.save_local_delta(delta, md5).await?;
                let _ = ret.send(Ok(()));
            }
            EditorCommand::ComposeRemoteDelta { client_delta, ret } => {
                let mut document = self.document.write().await;
                let _ = document.compose_delta(client_delta.clone())?;
                let md5 = document.md5();
                drop(document);
                let _ = ret.send(Ok(md5));
            }
            EditorCommand::ResetDelta { delta, ret } => {
                let mut document = self.document.write().await;
                let _ = document.set_delta(delta);
                let md5 = document.md5();
                drop(document);
                let _ = ret.send(Ok(md5));
            }
            EditorCommand::TransformDelta { delta, ret } => {
                let f = || async {
                    let read_guard = self.document.read().await;
                    let mut server_prime: Option<TextOperations> = None;
                    let client_prime: TextOperations;

                    if read_guard.is_empty() {
                        // Do nothing
                        client_prime = delta;
                    } else {
                        let (s_prime, c_prime) = read_guard.delta().transform(&delta)?;
                        client_prime = c_prime;
                        server_prime = Some(s_prime);
                    }
                    drop(read_guard);
                    Ok::<RichTextTransformDeltas, CollaborateError>(TransformDeltas {
                        client_prime,
                        server_prime,
                    })
                };
                let _ = ret.send(f().await);
            }
            EditorCommand::Insert { index, data, ret } => {
                let mut write_guard = self.document.write().await;
                let delta = write_guard.insert(index, data)?;
                let md5 = write_guard.md5();
                let _ = self.save_local_delta(delta, md5).await?;
                let _ = ret.send(Ok(()));
            }
            EditorCommand::Delete { interval, ret } => {
                let mut write_guard = self.document.write().await;
                let delta = write_guard.delete(interval)?;
                let md5 = write_guard.md5();
                let _ = self.save_local_delta(delta, md5).await?;
                let _ = ret.send(Ok(()));
            }
            EditorCommand::Format {
                interval,
                attribute,
                ret,
            } => {
                let mut write_guard = self.document.write().await;
                let delta = write_guard.format(interval, attribute)?;
                let md5 = write_guard.md5();
                let _ = self.save_local_delta(delta, md5).await?;
                let _ = ret.send(Ok(()));
            }
            EditorCommand::Replace { interval, data, ret } => {
                let mut write_guard = self.document.write().await;
                let delta = write_guard.replace(interval, data)?;
                let md5 = write_guard.md5();
                let _ = self.save_local_delta(delta, md5).await?;
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
                let UndoResult { delta } = write_guard.undo()?;
                let md5 = write_guard.md5();
                let _ = self.save_local_delta(delta, md5).await?;
                let _ = ret.send(Ok(()));
            }
            EditorCommand::Redo { ret } => {
                let mut write_guard = self.document.write().await;
                let UndoResult { delta } = write_guard.redo()?;
                let md5 = write_guard.md5();
                let _ = self.save_local_delta(delta, md5).await?;
                let _ = ret.send(Ok(()));
            }
            EditorCommand::ReadDeltaStr { ret } => {
                let data = self.document.read().await.delta_str();
                let _ = ret.send(Ok(data));
            }
            EditorCommand::ReadDelta { ret } => {
                let delta = self.document.read().await.delta().clone();
                let _ = ret.send(Ok(delta));
            }
        }
        Ok(())
    }

    async fn save_local_delta(&self, delta: TextOperations, md5: String) -> Result<RevId, FlowyError> {
        let delta_data = delta.json_bytes();
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id_pair();
        let user_id = self.user.user_id()?;
        let revision = Revision::new(
            &self.rev_manager.object_id,
            base_rev_id,
            rev_id,
            delta_data,
            &user_id,
            md5,
        );
        let _ = self.rev_manager.add_local_revision(&revision).await?;
        Ok(rev_id.into())
    }
}

pub(crate) struct TextBlockRevisionCompactor();
impl RevisionCompactor for TextBlockRevisionCompactor {
    fn bytes_from_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let delta = make_operations_from_revisions::<AttributeHashMap>(revisions)?;
        Ok(delta.json_bytes())
    }
}

pub(crate) type Ret<T> = oneshot::Sender<Result<T, CollaborateError>>;

pub(crate) enum EditorCommand {
    ComposeLocalDelta {
        delta: TextOperations,
        ret: Ret<()>,
    },
    ComposeRemoteDelta {
        client_delta: TextOperations,
        ret: Ret<OperationsMD5>,
    },
    ResetDelta {
        delta: TextOperations,
        ret: Ret<OperationsMD5>,
    },
    TransformDelta {
        delta: TextOperations,
        ret: Ret<RichTextTransformDeltas>,
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
    ReadDeltaStr {
        ret: Ret<String>,
    },
    #[allow(dead_code)]
    ReadDelta {
        ret: Ret<TextOperations>,
    },
}

impl std::fmt::Debug for EditorCommand {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        let s = match self {
            EditorCommand::ComposeLocalDelta { .. } => "ComposeLocalDelta",
            EditorCommand::ComposeRemoteDelta { .. } => "ComposeRemoteDelta",
            EditorCommand::ResetDelta { .. } => "ResetDelta",
            EditorCommand::TransformDelta { .. } => "TransformDelta",
            EditorCommand::Insert { .. } => "Insert",
            EditorCommand::Delete { .. } => "Delete",
            EditorCommand::Format { .. } => "Format",
            EditorCommand::Replace { .. } => "Replace",
            EditorCommand::CanUndo { .. } => "CanUndo",
            EditorCommand::CanRedo { .. } => "CanRedo",
            EditorCommand::Undo { .. } => "Undo",
            EditorCommand::Redo { .. } => "Redo",
            EditorCommand::ReadDeltaStr { .. } => "ReadDeltaStr",
            EditorCommand::ReadDelta { .. } => "ReadDocumentAsDelta",
        };
        f.write_str(s)
    }
}
