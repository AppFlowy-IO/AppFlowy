use async_stream::stream;
use bytes::Bytes;
use flowy_document_infra::{
    core::{history::UndoResult, Document},
    errors::DocumentError,
};
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
                    Err(e) => log::error!("{:?}", e),
                }
            })
            .await;
    }

    async fn handle_message(&self, msg: EditCommand) -> Result<(), DocumentError> {
        match msg {
            EditCommand::ComposeDelta { delta, ret } => {
                let result = self.composed_delta(delta).await;
                let _ = ret.send(result);
            },
            EditCommand::RemoteRevision { bytes, ret } => {
                let revision = Revision::try_from(bytes)?;
                let delta = RichTextDelta::from_bytes(&revision.delta_data)?;
                let rev_id: RevId = revision.rev_id.into();
                let (server_prime, client_prime) = self.document.read().await.delta().transform(&delta)?;
                let transform_delta = TransformDeltas {
                    client_prime,
                    server_prime,
                    server_rev_id: rev_id,
                };
                let _ = ret.send(Ok(transform_delta));
            },
            EditCommand::Insert { index, data, ret } => {
                let delta = self.document.write().await.insert(index, data);
                let _ = ret.send(delta);
            },
            EditCommand::Delete { interval, ret } => {
                let result = self.document.write().await.delete(interval);
                let _ = ret.send(result);
            },
            EditCommand::Format {
                interval,
                attribute,
                ret,
            } => {
                let result = self.document.write().await.format(interval, attribute);
                let _ = ret.send(result);
            },
            EditCommand::Replace { interval, data, ret } => {
                let result = self.document.write().await.replace(interval, data);
                let _ = ret.send(result);
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
        }
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, delta), fields(compose_result), err)]
    async fn composed_delta(&self, delta: RichTextDelta) -> Result<(), DocumentError> {
        // tracing::debug!("{:?} thread handle_message", thread::current(),);
        let mut document = self.document.write().await;
        tracing::Span::current().record(
            "composed_delta",
            &format!("doc_id:{} - {}", &self.doc_id, delta.to_json()).as_str(),
        );

        let result = document.compose_delta(delta);
        drop(document);

        result
    }
}

pub(crate) type Ret<T> = oneshot::Sender<Result<T, DocumentError>>;
pub(crate) enum EditCommand {
    ComposeDelta {
        delta: RichTextDelta,
        ret: Ret<()>,
    },
    RemoteRevision {
        bytes: Bytes,
        ret: Ret<TransformDeltas>,
    },
    Insert {
        index: usize,
        data: String,
        ret: Ret<RichTextDelta>,
    },
    Delete {
        interval: Interval,
        ret: Ret<RichTextDelta>,
    },
    Format {
        interval: Interval,
        attribute: RichTextAttribute,
        ret: Ret<RichTextDelta>,
    },

    Replace {
        interval: Interval,
        data: String,
        ret: Ret<RichTextDelta>,
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
}

pub(crate) struct TransformDeltas {
    pub client_prime: RichTextDelta,
    pub server_prime: RichTextDelta,
    pub server_rev_id: RevId,
}
