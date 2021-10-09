use crate::{
    entities::doc::{RevId, Revision},
    errors::DocResult,
    services::doc::{
        edit::{
            message::{DocumentMsg, TransformDeltas},
        },
        Document,
    },
};
use async_stream::stream;
use flowy_ot::core::{Delta, OperationTransformable};
use futures::stream::StreamExt;
use std::{convert::TryFrom, sync::Arc};
use tokio::sync::{mpsc, RwLock};

pub struct DocumentActor {
    document: Arc<RwLock<Document>>,
    receiver: Option<mpsc::UnboundedReceiver<DocumentMsg>>,
}

impl DocumentActor {
    pub fn new(
        delta: Delta,
        receiver: mpsc::UnboundedReceiver<DocumentMsg>,
    ) -> Self {
        let document = Arc::new(RwLock::new(Document::from_delta(delta)));
        Self {
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

    async fn handle_message(&self, msg: DocumentMsg) -> DocResult<()> {
        match msg {
            DocumentMsg::Delta { delta, ret } => {
                let result = self.compose_delta(delta).await;
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
            DocumentMsg::SaveDocument { rev_id: _, ret } => {
                // let result = self.save_to_disk(rev_id).await;
                let _ = ret.send(Ok(()));
            },
        }
        Ok(())
    }

    async fn compose_delta(&self, delta: Delta) -> DocResult<()> {
        let result = self.document.write().await.compose_delta(&delta);
        log::debug!(
            "Client compose push delta: {}. result: {}",
            delta.to_json(),
            self.document.read().await.to_json()
        );
        result
    }
}

// #[tracing::instrument(level = "debug", skip(self, params), err)]
// fn update_doc_on_server(&self, params: UpdateDocParams) -> Result<(),
//     DocError> {     let token = self.user.token()?;
//     let server = self.server.clone();
//     tokio::spawn(async move {
//         match server.update_doc(&token, params).await {
//             Ok(_) => {},
//             Err(e) => {
//                 // TODO: retry?
//                 log::error!("Update doc failed: {}", e);
//             },
//         }
//     });
//     Ok(())
// }
