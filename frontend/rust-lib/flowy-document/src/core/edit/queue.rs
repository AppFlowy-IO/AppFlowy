use crate::{
    context::DocumentUser,
    core::{web_socket::EditorCommandReceiver, DocumentRevisionManager},
};
use async_stream::stream;
use flowy_collaboration::{
    client_document::{history::UndoResult, ClientDocument, NewlineDoc},
    entities::revision::{RepeatedRevision, RevId, Revision},
    errors::CollaborateError,
    util::make_delta_from_revisions,
};
use flowy_error::FlowyError;
use futures::stream::StreamExt;
use lib_ot::{
    core::{Interval, OperationTransformable},
    rich_text::{RichTextAttribute, RichTextDelta},
};
use std::sync::Arc;
use tokio::sync::{oneshot, RwLock};

// The EditorCommandQueue executes each command that will alter the document in
// serial.
pub(crate) struct EditorCommandQueue {
    document: Arc<RwLock<ClientDocument>>,
    user: Arc<dyn DocumentUser>,
    rev_manager: Arc<DocumentRevisionManager>,
    receiver: Option<EditorCommandReceiver>,
}

impl EditorCommandQueue {
    pub(crate) fn new(
        user: Arc<dyn DocumentUser>,
        rev_manager: Arc<DocumentRevisionManager>,
        delta: RichTextDelta,
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
                    Ok(_) => {},
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
            },
            EditorCommand::ComposeRemoteDelta {
                revisions,
                client_delta,
                server_delta,
                ret,
            } => {
                let mut document = self.document.write().await;
                let _ = document.compose_delta(client_delta.clone())?;
                let md5 = document.md5();
                for revision in &revisions {
                    let _ = self.rev_manager.add_remote_revision(revision).await?;
                }

                let (base_rev_id, rev_id) = self.rev_manager.next_rev_id_pair();
                let doc_id = self.rev_manager.doc_id.clone();
                let user_id = self.user.user_id()?;
                let (client_revision, server_revision) = make_client_and_server_revision(
                    &doc_id,
                    &user_id,
                    base_rev_id,
                    rev_id,
                    client_delta,
                    Some(server_delta),
                    md5,
                );
                let _ = self.rev_manager.add_remote_revision(&client_revision).await?;
                let _ = ret.send(Ok(server_revision));
            },
            EditorCommand::OverrideDelta { revisions, delta, ret } => {
                let mut document = self.document.write().await;
                let _ = document.set_delta(delta);
                let md5 = document.md5();
                drop(document);

                let repeated_revision = RepeatedRevision::new(revisions);
                assert_eq!(repeated_revision.last().unwrap().md5, md5);
                let _ = self.rev_manager.reset_document(repeated_revision).await?;
                let _ = ret.send(Ok(()));
            },
            EditorCommand::TransformRevision { revisions, ret } => {
                let f = || async {
                    let new_delta = make_delta_from_revisions(revisions)?;
                    let read_guard = self.document.read().await;
                    let mut server_prime: Option<RichTextDelta> = None;
                    let client_prime: RichTextDelta;
                    // The document is empty if its text is equal to the initial text.
                    if read_guard.is_empty::<NewlineDoc>() {
                        // Do nothing
                        client_prime = new_delta;
                    } else {
                        let (s_prime, c_prime) = read_guard.delta().transform(&new_delta)?;
                        client_prime = c_prime;
                        server_prime = Some(s_prime);
                    }
                    drop(read_guard);
                    Ok::<TransformDeltas, CollaborateError>(TransformDeltas {
                        client_prime,
                        server_prime,
                    })
                };
                let _ = ret.send(f().await);
            },
            EditorCommand::Insert { index, data, ret } => {
                let mut write_guard = self.document.write().await;
                let delta = write_guard.insert(index, data)?;
                let md5 = write_guard.md5();
                let _ = self.save_local_delta(delta, md5).await?;
                let _ = ret.send(Ok(()));
            },
            EditorCommand::Delete { interval, ret } => {
                let mut write_guard = self.document.write().await;
                let delta = write_guard.delete(interval)?;
                let md5 = write_guard.md5();
                let _ = self.save_local_delta(delta, md5).await?;
                let _ = ret.send(Ok(()));
            },
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
            },
            EditorCommand::Replace { interval, data, ret } => {
                let mut write_guard = self.document.write().await;
                let delta = write_guard.replace(interval, data)?;
                let md5 = write_guard.md5();
                let _ = self.save_local_delta(delta, md5).await?;
                let _ = ret.send(Ok(()));
            },
            EditorCommand::CanUndo { ret } => {
                let _ = ret.send(self.document.read().await.can_undo());
            },
            EditorCommand::CanRedo { ret } => {
                let _ = ret.send(self.document.read().await.can_redo());
            },
            EditorCommand::Undo { ret } => {
                let mut write_guard = self.document.write().await;
                let UndoResult { delta } = write_guard.undo()?;
                let md5 = write_guard.md5();
                let _ = self.save_local_delta(delta, md5).await?;
                let _ = ret.send(Ok(()));
            },
            EditorCommand::Redo { ret } => {
                let mut write_guard = self.document.write().await;
                let UndoResult { delta } = write_guard.redo()?;
                let md5 = write_guard.md5();
                let _ = self.save_local_delta(delta, md5).await?;
                let _ = ret.send(Ok(()));
            },
            EditorCommand::ReadDocumentAsJson { ret } => {
                let data = self.document.read().await.to_json();
                let _ = ret.send(Ok(data));
            },
            EditorCommand::ReadDocumentAsDelta { ret } => {
                let delta = self.document.read().await.delta().clone();
                let _ = ret.send(Ok(delta));
            },
        }
        Ok(())
    }

    async fn save_local_delta(&self, delta: RichTextDelta, md5: String) -> Result<RevId, FlowyError> {
        let delta_data = delta.to_bytes();
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id_pair();
        let user_id = self.user.user_id()?;
        let revision = Revision::new(&self.rev_manager.doc_id, base_rev_id, rev_id, delta_data, &user_id, md5);
        let _ = self.rev_manager.add_local_revision(&revision).await?;
        Ok(rev_id.into())
    }
}

fn make_client_and_server_revision(
    doc_id: &str,
    user_id: &str,
    base_rev_id: i64,
    rev_id: i64,
    client_delta: RichTextDelta,
    server_delta: Option<RichTextDelta>,
    md5: DocumentMD5,
) -> (Revision, Option<Revision>) {
    let client_revision = Revision::new(
        &doc_id,
        base_rev_id,
        rev_id,
        client_delta.to_bytes(),
        &user_id,
        md5.clone(),
    );

    match server_delta {
        None => (client_revision, None),
        Some(server_delta) => {
            let server_revision = Revision::new(&doc_id, base_rev_id, rev_id, server_delta.to_bytes(), &user_id, md5);
            (client_revision, Some(server_revision))
        },
    }
}

pub(crate) type Ret<T> = oneshot::Sender<Result<T, CollaborateError>>;
pub(crate) type DocumentMD5 = String;

pub(crate) enum EditorCommand {
    ComposeLocalDelta {
        delta: RichTextDelta,
        ret: Ret<()>,
    },
    ComposeRemoteDelta {
        revisions: Vec<Revision>,
        client_delta: RichTextDelta,
        server_delta: RichTextDelta,
        ret: Ret<Option<Revision>>,
    },
    OverrideDelta {
        revisions: Vec<Revision>,
        delta: RichTextDelta,
        ret: Ret<()>,
    },
    TransformRevision {
        revisions: Vec<Revision>,
        ret: Ret<TransformDeltas>,
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
        attribute: RichTextAttribute,
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
    ReadDocumentAsJson {
        ret: Ret<String>,
    },
    #[allow(dead_code)]
    ReadDocumentAsDelta {
        ret: Ret<RichTextDelta>,
    },
}

impl std::fmt::Debug for EditorCommand {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        let s = match self {
            EditorCommand::ComposeLocalDelta { .. } => "ComposeLocalDelta",
            EditorCommand::ComposeRemoteDelta { .. } => "ComposeRemoteDelta",
            EditorCommand::OverrideDelta { .. } => "OverrideDelta",
            EditorCommand::TransformRevision { .. } => "TransformRevision",
            EditorCommand::Insert { .. } => "Insert",
            EditorCommand::Delete { .. } => "Delete",
            EditorCommand::Format { .. } => "Format",
            EditorCommand::Replace { .. } => "Replace",
            EditorCommand::CanUndo { .. } => "CanUndo",
            EditorCommand::CanRedo { .. } => "CanRedo",
            EditorCommand::Undo { .. } => "Undo",
            EditorCommand::Redo { .. } => "Redo",
            EditorCommand::ReadDocumentAsJson { .. } => "ReadDocumentAsJson",
            EditorCommand::ReadDocumentAsDelta { .. } => "ReadDocumentAsDelta",
        };
        f.write_str(s)
    }
}

pub(crate) struct TransformDeltas {
    pub client_prime: RichTextDelta,
    pub server_prime: Option<RichTextDelta>,
}
