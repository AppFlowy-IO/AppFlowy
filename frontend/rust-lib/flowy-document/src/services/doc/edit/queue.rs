use async_stream::stream;

use flowy_collaboration::{
    core::document::{history::UndoResult, Document},
    entities::revision::Revision,
    errors::CollaborateError,
};
use flowy_error::FlowyError;
use futures::stream::StreamExt;
use lib_ot::{
    core::{Interval, OperationTransformable},
    rich_text::{RichTextAttribute, RichTextDelta},
};
use std::sync::Arc;
use tokio::sync::{mpsc, oneshot, RwLock};

pub(crate) struct EditorCommandQueue {
    doc_id: String,
    document: Arc<RwLock<Document>>,
    receiver: Option<mpsc::UnboundedReceiver<EditorCommand>>,
}

impl EditorCommandQueue {
    pub(crate) fn new(doc_id: &str, delta: RichTextDelta, receiver: mpsc::UnboundedReceiver<EditorCommand>) -> Self {
        let document = Arc::new(RwLock::new(Document::from_delta(delta)));
        Self {
            doc_id: doc_id.to_owned(),
            document,
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
            .for_each(|msg| async {
                match self.handle_message(msg).await {
                    Ok(_) => {},
                    Err(e) => tracing::debug!("[EditCommandQueue]: {}", e),
                }
            })
            .await;
    }

    async fn handle_message(&self, msg: EditorCommand) -> Result<(), FlowyError> {
        match msg {
            EditorCommand::ComposeDelta { delta, ret } => {
                let result = self.composed_delta(delta).await;
                let _ = ret.send(result);
            },
            EditorCommand::ProcessRemoteRevision { revisions, ret } => {
                let f = || async {
                    let mut new_delta = RichTextDelta::new();
                    for revision in revisions {
                        match RichTextDelta::from_bytes(revision.delta_data) {
                            Ok(delta) => {
                                new_delta = new_delta.compose(&delta)?;
                            },
                            Err(e) => {
                                let err_msg = format!("Deserialize remote revision failed: {:?}", e);
                                log::error!("{}", err_msg);
                                return Err(CollaborateError::internal().context(err_msg));
                            },
                        }
                    }

                    let read_guard = self.document.read().await;
                    let (server_prime, client_prime) = read_guard.delta().transform(&new_delta)?;
                    drop(read_guard);

                    let transform_delta = TransformDeltas {
                        client_prime,
                        server_prime,
                    };

                    Ok::<TransformDeltas, CollaborateError>(transform_delta)
                };
                let _ = ret.send(f().await);
            },
            EditorCommand::Insert { index, data, ret } => {
                let mut write_guard = self.document.write().await;
                let delta = write_guard.insert(index, data)?;
                let md5 = write_guard.md5();
                let _ = ret.send(Ok((delta, md5)));
            },
            EditorCommand::Delete { interval, ret } => {
                let mut write_guard = self.document.write().await;
                let delta = write_guard.delete(interval)?;
                let md5 = write_guard.md5();
                let _ = ret.send(Ok((delta, md5)));
            },
            EditorCommand::Format {
                interval,
                attribute,
                ret,
            } => {
                let mut write_guard = self.document.write().await;
                let delta = write_guard.format(interval, attribute)?;
                let md5 = write_guard.md5();
                let _ = ret.send(Ok((delta, md5)));
            },
            EditorCommand::Replace { interval, data, ret } => {
                let mut write_guard = self.document.write().await;
                let delta = write_guard.replace(interval, data)?;
                let md5 = write_guard.md5();
                let _ = ret.send(Ok((delta, md5)));
            },
            EditorCommand::CanUndo { ret } => {
                let _ = ret.send(self.document.read().await.can_undo());
            },
            EditorCommand::CanRedo { ret } => {
                let _ = ret.send(self.document.read().await.can_redo());
            },
            EditorCommand::Undo { ret } => {
                let result = self.document.write().await.undo();
                let _ = ret.send(result);
            },
            EditorCommand::Redo { ret } => {
                let result = self.document.write().await.redo();
                let _ = ret.send(result);
            },
            EditorCommand::ReadDoc { ret } => {
                let data = self.document.read().await.to_json();
                let _ = ret.send(Ok(data));
            },
            EditorCommand::ReadDocDelta { ret } => {
                let delta = self.document.read().await.delta().clone();
                let _ = ret.send(Ok(delta));
            },
        }
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, delta), fields(compose_result), err)]
    async fn composed_delta(&self, delta: RichTextDelta) -> Result<String, CollaborateError> {
        // tracing::debug!("{:?} thread handle_message", thread::current(),);
        let mut document = self.document.write().await;
        tracing::Span::current().record(
            "composed_delta",
            &format!("doc_id:{} - {}", &self.doc_id, delta.to_json()).as_str(),
        );

        let _ = document.compose_delta(delta)?;
        let md5 = document.md5();
        drop(document);

        Ok(md5)
    }
}

pub(crate) type Ret<T> = oneshot::Sender<Result<T, CollaborateError>>;
pub(crate) type NewDelta = (RichTextDelta, String);
pub(crate) type DocumentMD5 = String;

#[allow(dead_code)]
pub(crate) enum EditorCommand {
    ComposeDelta {
        delta: RichTextDelta,
        ret: Ret<DocumentMD5>,
    },
    ProcessRemoteRevision {
        revisions: Vec<Revision>,
        ret: Ret<TransformDeltas>,
    },
    Insert {
        index: usize,
        data: String,
        ret: Ret<NewDelta>,
    },
    Delete {
        interval: Interval,
        ret: Ret<NewDelta>,
    },
    Format {
        interval: Interval,
        attribute: RichTextAttribute,
        ret: Ret<NewDelta>,
    },

    Replace {
        interval: Interval,
        data: String,
        ret: Ret<NewDelta>,
    },
    CanUndo {
        ret: oneshot::Sender<bool>,
    },
    CanRedo {
        ret: oneshot::Sender<bool>,
    },
    Undo {
        ret: Ret<UndoResult>,
    },
    Redo {
        ret: Ret<UndoResult>,
    },
    ReadDoc {
        ret: Ret<String>,
    },
    ReadDocDelta {
        ret: Ret<RichTextDelta>,
    },
}

pub(crate) struct TransformDeltas {
    pub client_prime: RichTextDelta,
    pub server_prime: RichTextDelta,
}
