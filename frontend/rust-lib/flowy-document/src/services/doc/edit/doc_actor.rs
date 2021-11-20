use async_stream::stream;
use bytes::Bytes;
use flowy_document_infra::{
    core::{history::UndoResult, Document},
    entities::doc::{RevId, Revision},
    errors::DocumentError,
};
use futures::stream::StreamExt;
use lib_ot::core::{Attribute, Delta, Interval, OperationTransformable};
use std::{convert::TryFrom, sync::Arc};
use tokio::sync::{mpsc, oneshot, RwLock};

pub struct DocumentActor {
    doc_id: String,
    document: Arc<RwLock<Document>>,
    receiver: Option<mpsc::UnboundedReceiver<DocumentMsg>>,
}

impl DocumentActor {
    pub fn new(doc_id: &str, delta: Delta, receiver: mpsc::UnboundedReceiver<DocumentMsg>) -> Self {
        let document = Arc::new(RwLock::new(Document::from_delta(delta)));
        Self {
            doc_id: doc_id.to_owned(),
            document,
            receiver: Some(receiver),
        }
    }

    pub async fn run(mut self) {
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

    async fn handle_message(&self, msg: DocumentMsg) -> Result<(), DocumentError> {
        match msg {
            DocumentMsg::Delta { delta, ret } => {
                let result = self.composed_delta(delta).await;
                let _ = ret.send(result);
            },
            DocumentMsg::RemoteRevision { bytes, ret } => {
                let revision = Revision::try_from(bytes)?;
                let delta = Delta::from_bytes(&revision.delta_data)?;
                let rev_id: RevId = revision.rev_id.into();
                let (server_prime, client_prime) = self.document.read().await.delta().transform(&delta)?;
                let transform_delta = TransformDeltas {
                    client_prime,
                    server_prime,
                    server_rev_id: rev_id,
                };
                let _ = ret.send(Ok(transform_delta));
            },
            DocumentMsg::Insert { index, data, ret } => {
                let delta = self.document.write().await.insert(index, data);
                let _ = ret.send(delta);
            },
            DocumentMsg::Delete { interval, ret } => {
                let result = self.document.write().await.delete(interval);
                let _ = ret.send(result);
            },
            DocumentMsg::Format {
                interval,
                attribute,
                ret,
            } => {
                let result = self.document.write().await.format(interval, attribute);
                let _ = ret.send(result);
            },
            DocumentMsg::Replace { interval, data, ret } => {
                let result = self.document.write().await.replace(interval, data);
                let _ = ret.send(result);
            },
            DocumentMsg::CanUndo { ret } => {
                let _ = ret.send(self.document.read().await.can_undo());
            },
            DocumentMsg::CanRedo { ret } => {
                let _ = ret.send(self.document.read().await.can_redo());
            },
            DocumentMsg::Undo { ret } => {
                let result = self.document.write().await.undo();
                let _ = ret.send(result);
            },
            DocumentMsg::Redo { ret } => {
                let result = self.document.write().await.redo();
                let _ = ret.send(result);
            },
            DocumentMsg::Doc { ret } => {
                let data = self.document.read().await.to_json();
                let _ = ret.send(Ok(data));
            },
        }
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, delta), fields(compose_result), err)]
    async fn composed_delta(&self, delta: Delta) -> Result<(), DocumentError> {
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

pub type Ret<T> = oneshot::Sender<Result<T, DocumentError>>;
pub enum DocumentMsg {
    Delta {
        delta: Delta,
        ret: Ret<()>,
    },
    RemoteRevision {
        bytes: Bytes,
        ret: Ret<TransformDeltas>,
    },
    Insert {
        index: usize,
        data: String,
        ret: Ret<Delta>,
    },
    Delete {
        interval: Interval,
        ret: Ret<Delta>,
    },
    Format {
        interval: Interval,
        attribute: Attribute,
        ret: Ret<Delta>,
    },

    Replace {
        interval: Interval,
        data: String,
        ret: Ret<Delta>,
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
    Doc {
        ret: Ret<String>,
    },
}

pub struct TransformDeltas {
    pub client_prime: Delta,
    pub server_prime: Delta,
    pub server_rev_id: RevId,
}
