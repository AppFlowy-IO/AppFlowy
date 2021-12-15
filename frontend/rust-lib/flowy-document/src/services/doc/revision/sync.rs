use crate::services::doc::{
    edit::ClientDocEditor,
    revision::{RevisionIterator, RevisionManager},
    DocumentWebSocket,
    SYNC_INTERVAL_IN_MILLIS,
};
use async_stream::stream;
use bytes::Bytes;
use flowy_collaboration::entities::ws::{WsDataType, WsDocumentData};
use flowy_error::{internal_error, FlowyResult};
use futures::stream::StreamExt;
use lib_ot::revision::{RevId, RevisionRange};
use std::{convert::TryFrom, sync::Arc};
use tokio::{
    sync::{broadcast, mpsc},
    task::spawn_blocking,
    time::{interval, Duration},
};

pub(crate) struct RevisionDownStream {
    editor: Arc<ClientDocEditor>,
    rev_manager: Arc<RevisionManager>,
    ws_msg_rx: Option<mpsc::UnboundedReceiver<WsDocumentData>>,
    ws_sender: Arc<dyn DocumentWebSocket>,
    stop_rx: Option<SteamStopRx>,
}

impl RevisionDownStream {
    pub(crate) fn new(
        editor: Arc<ClientDocEditor>,
        rev_manager: Arc<RevisionManager>,
        ws_msg_rx: mpsc::UnboundedReceiver<WsDocumentData>,
        ws_sender: Arc<dyn DocumentWebSocket>,
        stop_rx: SteamStopRx,
    ) -> Self {
        RevisionDownStream {
            editor,
            rev_manager,
            ws_msg_rx: Some(ws_msg_rx),
            ws_sender,
            stop_rx: Some(stop_rx),
        }
    }

    pub async fn run(mut self) {
        let mut receiver = self.ws_msg_rx.take().expect("Only take once");
        let mut stop_rx = self.stop_rx.take().expect("Only take once");
        let doc_id = self.editor.doc_id.clone();
        let stream = stream! {
            loop {
                tokio::select! {
                    result = receiver.recv() => {
                        match result {
                            Some(msg) => {
                                yield msg
                            },
                            None => {
                                tracing::debug!("[RevisionDownStream:{}] loop exit", doc_id);
                                break;
                            },
                        }
                    },
                    _ = stop_rx.recv() => {
                        tracing::debug!("[RevisionDownStream:{}] loop exit", doc_id);
                        break
                    },
                };
            }
        };

        stream
            .for_each(|msg| async {
                match self.handle_message(msg).await {
                    Ok(_) => {},
                    Err(e) => log::error!("[RevisionDownStream:{}] error: {}", self.editor.doc_id, e),
                }
            })
            .await;
    }

    async fn handle_message(&self, msg: WsDocumentData) -> FlowyResult<()> {
        let WsDocumentData { doc_id: _, ty, data } = msg;
        let bytes = spawn_blocking(move || Bytes::from(data))
            .await
            .map_err(internal_error)?;

        tracing::debug!("[RevisionDownStream]: receives new message: {:?}", ty);
        match ty {
            WsDataType::PushRev => {
                let _ = self.editor.handle_push_rev(bytes).await?;
            },
            WsDataType::PullRev => {
                let range = RevisionRange::try_from(bytes)?;
                let revision = self.rev_manager.mk_revisions(range).await?;
                let _ = self.ws_sender.send(revision.into());
            },
            WsDataType::Acked => {
                let rev_id = RevId::try_from(bytes)?;
                let _ = self.rev_manager.ack_revision(rev_id).await?;
            },
            WsDataType::Conflict => {},
        }

        Ok(())
    }
}

// RevisionUpStream
pub(crate) enum UpStreamMsg {
    Tick,
}

pub type SteamStopRx = broadcast::Receiver<()>;
pub type SteamStopTx = broadcast::Sender<()>;

pub(crate) struct RevisionUpStream {
    revisions: Arc<dyn RevisionIterator>,
    ws_sender: Arc<dyn DocumentWebSocket>,
    stop_rx: Option<SteamStopRx>,
    doc_id: String,
}

impl RevisionUpStream {
    pub(crate) fn new(
        doc_id: &str,
        revisions: Arc<dyn RevisionIterator>,
        ws_sender: Arc<dyn DocumentWebSocket>,
        stop_rx: SteamStopRx,
    ) -> Self {
        Self {
            revisions,
            ws_sender,
            stop_rx: Some(stop_rx),
            doc_id: doc_id.to_owned(),
        }
    }

    pub async fn run(mut self) {
        let (tx, mut rx) = mpsc::unbounded_channel();
        let mut stop_rx = self.stop_rx.take().expect("Only take once");
        let doc_id = self.doc_id.clone();
        tokio::spawn(tick(tx));
        let stream = stream! {
            loop {
                tokio::select! {
                    result = rx.recv() => {
                        match result {
                            Some(msg) => yield msg,
                            None => break,
                        }
                    },
                    _ = stop_rx.recv() => {
                        tracing::debug!("[RevisionUpStream:{}] loop exit", doc_id);
                        break
                    },
                };
            }
        };
        stream
            .for_each(|msg| async {
                match self.handle_msg(msg).await {
                    Ok(_) => {},
                    Err(e) => log::error!("[RevisionUpStream]: send msg failed, {:?}", e),
                }
            })
            .await;
    }

    async fn handle_msg(&self, msg: UpStreamMsg) -> FlowyResult<()> {
        match msg {
            UpStreamMsg::Tick => self.send_next_revision().await,
        }
    }

    async fn send_next_revision(&self) -> FlowyResult<()> {
        match self.revisions.next().await? {
            None => {
                tracing::debug!("Finish synchronizing revisions");
                Ok(())
            },
            Some(record) => {
                tracing::debug!(
                    "[RevisionUpStream]: processes revision: {}:{:?}",
                    record.revision.doc_id,
                    record.revision.rev_id
                );
                self.ws_sender.send(record.revision.into()).map_err(internal_error)
                // let _ = tokio::time::timeout(Duration::from_millis(2000),
                // ret.recv()).await;
            },
        }
    }
}

async fn tick(sender: mpsc::UnboundedSender<UpStreamMsg>) {
    let mut i = interval(Duration::from_millis(SYNC_INTERVAL_IN_MILLIS));
    while sender.send(UpStreamMsg::Tick).is_ok() {
        i.tick().await;
    }
}
