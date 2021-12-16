use crate::services::doc::{DocumentWebSocket, DocumentWsHandler, SYNC_INTERVAL_IN_MILLIS};
use async_stream::stream;
use bytes::Bytes;
use flowy_collaboration::{
    entities::ws::{DocumentWSData, DocumentWSDataType},
    Revision,
};
use flowy_error::{internal_error, FlowyError, FlowyResult};
use futures::stream::StreamExt;
use lib_infra::future::FutureResult;
use lib_ot::revision::{RevId, RevisionRange};
use lib_ws::WSConnectState;
use std::{convert::TryFrom, sync::Arc};
use tokio::{
    sync::{
        broadcast,
        mpsc,
        mpsc::{UnboundedReceiver, UnboundedSender},
    },
    task::spawn_blocking,
    time::{interval, Duration},
};

pub(crate) struct WebSocketManager {
    doc_id: String,
    data_provider: Arc<dyn DocumentSinkDataProvider>,
    stream_consumer: Arc<dyn DocumentWebSocketSteamConsumer>,
    ws: Arc<dyn DocumentWebSocket>,
    ws_msg_tx: UnboundedSender<DocumentWSData>,
    ws_msg_rx: Option<UnboundedReceiver<DocumentWSData>>,
    stop_sync_tx: SinkStopTx,
}

impl WebSocketManager {
    pub(crate) fn new(
        doc_id: &str,
        ws: Arc<dyn DocumentWebSocket>,
        data_provider: Arc<dyn DocumentSinkDataProvider>,
        stream_consumer: Arc<dyn DocumentWebSocketSteamConsumer>,
    ) -> Self {
        let (ws_msg_tx, ws_msg_rx) = mpsc::unbounded_channel();
        let (stop_sync_tx, _) = tokio::sync::broadcast::channel(2);
        let doc_id = doc_id.to_string();
        let mut manager = WebSocketManager {
            doc_id,
            data_provider,
            stream_consumer,
            ws,
            ws_msg_tx,
            ws_msg_rx: Some(ws_msg_rx),
            stop_sync_tx,
        };
        manager.start_sync();
        manager
    }

    fn start_sync(&mut self) {
        let ws_msg_rx = self.ws_msg_rx.take().expect("Only take once");
        let sink = DocumentWebSocketSink::new(
            &self.doc_id,
            self.data_provider.clone(),
            self.ws.clone(),
            self.stop_sync_tx.subscribe(),
        );
        let stream = DocumentWebSocketStream::new(
            &self.doc_id,
            self.stream_consumer.clone(),
            ws_msg_rx,
            self.ws.clone(),
            self.stop_sync_tx.subscribe(),
        );
        tokio::spawn(sink.run());
        tokio::spawn(stream.run());
        self.notify_user_conn();
    }

    pub(crate) fn stop(&self) {
        if self.stop_sync_tx.send(()).is_ok() {
            tracing::debug!("{} stop sync", self.doc_id)
        }
    }

    #[tracing::instrument(level = "debug", skip(self))]
    fn notify_user_conn(&self) {
        // let rev_id: RevId = self.rev_manager.rev_id().into();
        // if let Ok(user_id) = self.user.user_id() {
        //     let action = OpenDocAction::new(&user_id, &self.doc_id, &rev_id,
        // &self.ws_sender);     let strategy =
        // ExponentialBackoff::from_millis(50).take(3);     let retry =
        // Retry::spawn(strategy, action);     tokio::spawn(async move {
        //         match retry.await {
        //             Ok(_) => log::debug!("Notify open doc success"),
        //             Err(e) => log::error!("Notify open doc failed: {}", e),
        //         }
        //     });
        // }
    }
}

impl DocumentWsHandler for WebSocketManager {
    fn receive(&self, doc_data: DocumentWSData) {
        match self.ws_msg_tx.send(doc_data) {
            Ok(_) => {},
            Err(e) => tracing::error!("❌Propagate ws message failed. {}", e),
        }
    }

    fn connect_state_changed(&self, state: &WSConnectState) {
        match state {
            WSConnectState::Init => {},
            WSConnectState::Connecting => {},
            WSConnectState::Connected => self.notify_user_conn(),
            WSConnectState::Disconnected => {},
        }
    }
}

pub trait DocumentWebSocketSteamConsumer: Send + Sync {
    fn receive_push_revision(&self, bytes: Bytes) -> FutureResult<(), FlowyError>;
    fn make_revision_from_range(&self, range: RevisionRange) -> FutureResult<Revision, FlowyError>;
    fn ack_revision(&self, rev_id: i64) -> FutureResult<(), FlowyError>;
}

pub(crate) struct DocumentWebSocketStream {
    doc_id: String,
    consumer: Arc<dyn DocumentWebSocketSteamConsumer>,
    ws_msg_rx: Option<mpsc::UnboundedReceiver<DocumentWSData>>,
    ws_sender: Arc<dyn DocumentWebSocket>,
    stop_rx: Option<SinkStopRx>,
}

impl DocumentWebSocketStream {
    pub(crate) fn new(
        doc_id: &str,
        consumer: Arc<dyn DocumentWebSocketSteamConsumer>,
        ws_msg_rx: mpsc::UnboundedReceiver<DocumentWSData>,
        ws_sender: Arc<dyn DocumentWebSocket>,
        stop_rx: SinkStopRx,
    ) -> Self {
        DocumentWebSocketStream {
            doc_id: doc_id.to_owned(),
            consumer,
            ws_msg_rx: Some(ws_msg_rx),
            ws_sender,
            stop_rx: Some(stop_rx),
        }
    }

    pub async fn run(mut self) {
        let mut receiver = self.ws_msg_rx.take().expect("Only take once");
        let mut stop_rx = self.stop_rx.take().expect("Only take once");
        let doc_id = self.doc_id.clone();
        let stream = stream! {
            loop {
                tokio::select! {
                    result = receiver.recv() => {
                        match result {
                            Some(msg) => {
                                yield msg
                            },
                            None => {
                                tracing::debug!("[DocumentStream:{}] loop exit", doc_id);
                                break;
                            },
                        }
                    },
                    _ = stop_rx.recv() => {
                        tracing::debug!("[DocumentStream:{}] loop exit", doc_id);
                        break
                    },
                };
            }
        };

        stream
            .for_each(|msg| async {
                match self.handle_message(msg).await {
                    Ok(_) => {},
                    Err(e) => log::error!("[DocumentStream:{}] error: {}", self.doc_id, e),
                }
            })
            .await;
    }

    async fn handle_message(&self, msg: DocumentWSData) -> FlowyResult<()> {
        let DocumentWSData {
            doc_id: _,
            ty,
            data,
            id: _,
        } = msg;
        let bytes = spawn_blocking(move || Bytes::from(data))
            .await
            .map_err(internal_error)?;

        tracing::debug!("[DocumentStream]: receives new message: {:?}", ty);
        match ty {
            DocumentWSDataType::PushRev => {
                let _ = self.consumer.receive_push_revision(bytes).await?;
            },
            DocumentWSDataType::PullRev => {
                let range = RevisionRange::try_from(bytes)?;
                let revision = self.consumer.make_revision_from_range(range).await?;
                let _ = self.ws_sender.send(revision.into());
            },
            DocumentWSDataType::Acked => {
                let rev_id = RevId::try_from(bytes)?;
                let _ = self.consumer.ack_revision(rev_id.into()).await;
            },
            DocumentWSDataType::UserConnect => {},
        }

        Ok(())
    }
}

pub(crate) type Tick = ();
pub(crate) type SinkStopRx = broadcast::Receiver<()>;
pub(crate) type SinkStopTx = broadcast::Sender<()>;

pub trait DocumentSinkDataProvider: Send + Sync {
    fn next(&self) -> FutureResult<Option<DocumentWSData>, FlowyError>;
}

pub(crate) struct DocumentWebSocketSink {
    provider: Arc<dyn DocumentSinkDataProvider>,
    ws_sender: Arc<dyn DocumentWebSocket>,
    stop_rx: Option<SinkStopRx>,
    doc_id: String,
}

impl DocumentWebSocketSink {
    pub(crate) fn new(
        doc_id: &str,
        provider: Arc<dyn DocumentSinkDataProvider>,
        ws_sender: Arc<dyn DocumentWebSocket>,
        stop_rx: SinkStopRx,
    ) -> Self {
        Self {
            provider,
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
                        tracing::debug!("[DocumentSink:{}] loop exit", doc_id);
                        break
                    },
                };
            }
        };
        stream
            .for_each(|_| async {
                match self.send_next_revision().await {
                    Ok(_) => {},
                    Err(e) => log::error!("[DocumentSink]: send msg failed, {:?}", e),
                }
            })
            .await;
    }

    async fn send_next_revision(&self) -> FlowyResult<()> {
        match self.provider.next().await? {
            None => {
                tracing::debug!("Finish synchronizing revisions");
                Ok(())
            },
            Some(data) => {
                self.ws_sender.send(data).map_err(internal_error)
                // let _ = tokio::time::timeout(Duration::from_millis(2000),
            },
        }
    }
}

async fn tick(sender: mpsc::UnboundedSender<Tick>) {
    let mut interval = interval(Duration::from_millis(SYNC_INTERVAL_IN_MILLIS));
    while sender.send(()).is_ok() {
        interval.tick().await;
    }
}
