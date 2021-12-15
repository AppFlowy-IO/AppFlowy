use async_stream::stream;
use bytes::Bytes;
use flowy_collaboration::{
    core::document::{history::UndoResult, Document},
    errors::CollaborateError,
};
use flowy_error::FlowyError;
use futures::stream::StreamExt;
use lib_ot::{
    core::{Interval, OperationTransformable},
    revision::{RevId, Revision},
    rich_text::{RichTextAttribute, RichTextDelta},
};
use std::{convert::TryFrom, sync::Arc};
use tokio::sync::{mpsc, oneshot, RwLock};

pub(crate) struct EditCommandQueue {
    doc_id: String,
    document: Arc<RwLock<Document>>,
    receiver: Option<mpsc::UnboundedReceiver<EditCommand>>,
}

impl EditCommandQueue {
    pub(crate) fn new(doc_id: &str, delta: RichTextDelta, receiver: mpsc::UnboundedReceiver<EditCommand>) -> Self {
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

    async fn handle_message(&self, msg: EditCommand) -> Result<(), FlowyError> {
        match msg {
            EditCommand::ComposeDelta { delta, ret } => {
                let result = self.composed_delta(delta).await;
                let _ = ret.send(result);
            },
            EditCommand::ProcessRemoteRevision { bytes, ret } => {
                let f = || async {
                    let revision = Revision::try_from(bytes)?;
                    let delta = RichTextDelta::from_bytes(&revision.delta_data)?;
                    let server_rev_id: RevId = revision.rev_id.into();
                    let read_guard = self.document.read().await;
                    let (server_prime, client_prime) = read_guard.delta().transform(&delta)?;
                    drop(read_guard);

                    let transform_delta = TransformDeltas {
                        client_prime,
                        server_prime,
                        server_rev_id,
                    };

                    Ok::<TransformDeltas, CollaborateError>(transform_delta)
                };
                let _ = ret.send(f().await);
            },
            EditCommand::Insert { index, data, ret } => {
                let mut write_guard = self.document.write().await;
                let delta = write_guard.insert(index, data)?;
                let md5 = write_guard.md5();
                let _ = ret.send(Ok((delta, md5)));
            },
            EditCommand::Delete { interval, ret } => {
                let mut write_guard = self.document.write().await;
                let delta = write_guard.delete(interval)?;
                let md5 = write_guard.md5();
                let _ = ret.send(Ok((delta, md5)));
            },
            EditCommand::Format {
                interval,
                attribute,
                ret,
            } => {
                let mut write_guard = self.document.write().await;
                let delta = write_guard.format(interval, attribute)?;
                let md5 = write_guard.md5();
                let _ = ret.send(Ok((delta, md5)));
            },
            EditCommand::Replace { interval, data, ret } => {
                let mut write_guard = self.document.write().await;
                let delta = write_guard.replace(interval, data)?;
                let md5 = write_guard.md5();
                let _ = ret.send(Ok((delta, md5)));
            },
            EditCommand::CanUndo { ret } => {
                let _ = ret.send(self.document.read().await.can_undo());
            },
            EditCommand::CanRedo { ret } => {
                let _ = ret.send(self.document.read().await.can_redo());
            },
            EditCommand::Undo { ret } => {
                let result = self.document.write().await.undo();
                let _ = ret.send(result);
            },
            EditCommand::Redo { ret } => {
                let result = self.document.write().await.redo();
                let _ = ret.send(result);
            },
            EditCommand::ReadDoc { ret } => {
                let data = self.document.read().await.to_json();
                let _ = ret.send(Ok(data));
            },
            EditCommand::ReadDocDelta { ret } => {
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
pub(crate) enum EditCommand {
    ComposeDelta {
        delta: RichTextDelta,
        ret: Ret<DocumentMD5>,
    },
    ProcessRemoteRevision {
        bytes: Bytes,
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
    pub server_rev_id: RevId,
}
