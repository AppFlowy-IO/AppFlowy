use crate::{
    core::SYNC_INTERVAL_IN_MILLIS,
    ws_receivers::{DocumentWSReceiver, DocumentWebSocket},
};
use async_stream::stream;
use async_trait::async_trait;
use bytes::Bytes;
use flowy_collaboration::entities::{
    revision::{RevId, RevisionRange},
    ws::{DocumentClientWSData, DocumentServerWSData, DocumentServerWSDataType, NewDocumentUser},
};
use flowy_error::{internal_error, FlowyError, FlowyResult};
use futures::stream::StreamExt;
use lib_infra::future::FutureResult;
use lib_ws::WSConnectState;
use std::{convert::TryFrom, sync::Arc};
use tokio::{
    sync::{
        broadcast,
        mpsc,
        mpsc::{Receiver, Sender},
    },
    task::spawn_blocking,
    time::{interval, Duration},
};

// The consumer consumes the messages pushed by the web socket.
pub trait DocumentWSSteamConsumer: Send + Sync {
    fn receive_push_revision(&self, bytes: Bytes) -> FutureResult<(), FlowyError>;
    fn receive_ack(&self, id: String, ty: DocumentServerWSDataType) -> FutureResult<(), FlowyError>;
    fn receive_new_user_connect(&self, new_user: NewDocumentUser) -> FutureResult<(), FlowyError>;
    fn pull_revisions_in_range(&self, range: RevisionRange) -> FutureResult<(), FlowyError>;
}

// The sink provides the data that will be sent through the web socket to the
// backend.
pub trait DocumentWSSinkDataProvider: Send + Sync {
    fn next(&self) -> FutureResult<Option<DocumentClientWSData>, FlowyError>;
}

pub struct DocumentWebSocketManager {
    doc_id: String,
    data_provider: Arc<dyn DocumentWSSinkDataProvider>,
    stream_consumer: Arc<dyn DocumentWSSteamConsumer>,
    ws_conn: Arc<dyn DocumentWebSocket>,
    ws_passthrough_tx: Sender<DocumentServerWSData>,
    ws_passthrough_rx: Option<Receiver<DocumentServerWSData>>,
    state_passthrough_tx: broadcast::Sender<WSConnectState>,
    stop_sync_tx: SinkStopTx,
}

impl DocumentWebSocketManager {
    pub(crate) fn new(
        doc_id: &str,
        ws_conn: Arc<dyn DocumentWebSocket>,
        data_provider: Arc<dyn DocumentWSSinkDataProvider>,
        stream_consumer: Arc<dyn DocumentWSSteamConsumer>,
    ) -> Self {
        let (ws_passthrough_tx, ws_passthrough_rx) = mpsc::channel(1000);
        let (stop_sync_tx, _) = tokio::sync::broadcast::channel(2);
        let doc_id = doc_id.to_string();
        let (state_passthrough_tx, _) = broadcast::channel(2);
        let mut manager = DocumentWebSocketManager {
            doc_id,
            data_provider,
            stream_consumer,
            ws_conn,
            ws_passthrough_tx,
            ws_passthrough_rx: Some(ws_passthrough_rx),
            state_passthrough_tx,
            stop_sync_tx,
        };
        manager.run();
        manager
    }

    fn run(&mut self) {
        let ws_msg_rx = self.ws_passthrough_rx.take().expect("Only take once");
        let sink = DocumentWSSink::new(
            &self.doc_id,
            self.data_provider.clone(),
            self.ws_conn.clone(),
            self.stop_sync_tx.subscribe(),
        );
        let stream = DocumentWSStream::new(
            &self.doc_id,
            self.stream_consumer.clone(),
            ws_msg_rx,
            self.stop_sync_tx.subscribe(),
        );
        tokio::spawn(sink.run());
        tokio::spawn(stream.run());
    }

    pub fn scribe_state(&self) -> broadcast::Receiver<WSConnectState> { self.state_passthrough_tx.subscribe() }

    pub(crate) fn stop(&self) {
        if self.stop_sync_tx.send(()).is_ok() {
            tracing::debug!("{} stop sync", self.doc_id)
        }
    }
}

//  DocumentWebSocketManager registers itself as a DocumentWSReceiver for each
//  opened document. It will receive the web socket message and parser it into
//  DocumentServerWSData.
#[async_trait]
impl DocumentWSReceiver for DocumentWebSocketManager {
    #[tracing::instrument(level = "debug", skip(self, doc_data), err)]
    async fn receive_ws_data(&self, doc_data: DocumentServerWSData) -> Result<(), FlowyError> {
        let _ = self.ws_passthrough_tx.send(doc_data).await.map_err(|e| {
            let err_msg = format!("{} passthrough error: {}", self.doc_id, e);
            FlowyError::internal().context(err_msg)
        })?;
        Ok(())
    }

    fn connect_state_changed(&self, state: WSConnectState) {
        match self.state_passthrough_tx.send(state) {
            Ok(_) => {},
            Err(e) => tracing::error!("{}", e),
        }
    }
}

impl std::ops::Drop for DocumentWebSocketManager {
    fn drop(&mut self) { tracing::trace!("{} DocumentWebSocketManager was dropped", self.doc_id) }
}

pub struct DocumentWSStream {
    doc_id: String,
    consumer: Arc<dyn DocumentWSSteamConsumer>,
    ws_msg_rx: Option<mpsc::Receiver<DocumentServerWSData>>,
    stop_rx: Option<SinkStopRx>,
}

impl DocumentWSStream {
    pub fn new(
        doc_id: &str,
        consumer: Arc<dyn DocumentWSSteamConsumer>,
        ws_msg_rx: mpsc::Receiver<DocumentServerWSData>,
        stop_rx: SinkStopRx,
    ) -> Self {
        DocumentWSStream {
            doc_id: doc_id.to_owned(),
            consumer,
            ws_msg_rx: Some(ws_msg_rx),
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

    async fn handle_message(&self, msg: DocumentServerWSData) -> FlowyResult<()> {
        let DocumentServerWSData { doc_id: _, ty, data } = msg;
        let bytes = spawn_blocking(move || Bytes::from(data))
            .await
            .map_err(internal_error)?;

        tracing::trace!("[DocumentStream]: new message: {:?}", ty);
        match ty {
            DocumentServerWSDataType::ServerPushRev => {
                let _ = self.consumer.receive_push_revision(bytes).await?;
            },
            DocumentServerWSDataType::ServerPullRev => {
                let range = RevisionRange::try_from(bytes)?;
                let _ = self.consumer.pull_revisions_in_range(range).await?;
            },
            DocumentServerWSDataType::ServerAck => {
                let rev_id = RevId::try_from(bytes).unwrap().value;
                let _ = self.consumer.receive_ack(rev_id.to_string(), ty).await;
            },
            DocumentServerWSDataType::UserConnect => {
                let new_user = NewDocumentUser::try_from(bytes)?;
                let _ = self.consumer.receive_new_user_connect(new_user).await;
            },
        }
        Ok(())
    }
}

type SinkStopRx = broadcast::Receiver<()>;
type SinkStopTx = broadcast::Sender<()>;
pub struct DocumentWSSink {
    provider: Arc<dyn DocumentWSSinkDataProvider>,
    ws_sender: Arc<dyn DocumentWebSocket>,
    stop_rx: Option<SinkStopRx>,
    doc_id: String,
}

impl DocumentWSSink {
    pub fn new(
        doc_id: &str,
        provider: Arc<dyn DocumentWSSinkDataProvider>,
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
        let (tx, mut rx) = mpsc::channel(1);
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
                        tracing::trace!("[DocumentSink:{}] loop exit", doc_id);
                        break
                    },
                };
            }
        };
        stream
            .for_each(|_| async {
                match self.send_next_revision().await {
                    Ok(_) => {},
                    Err(e) => log::error!("[DocumentSink] send failed, {:?}", e),
                }
            })
            .await;
    }

    async fn send_next_revision(&self) -> FlowyResult<()> {
        match self.provider.next().await? {
            None => {
                tracing::trace!("Finish synchronizing revisions");
                Ok(())
            },
            Some(data) => {
                tracing::trace!("[DocumentSink] send: {}:{}-{:?}", data.doc_id, data.id(), data.ty);
                self.ws_sender.send(data)
            },
        }
    }
}

async fn tick(sender: mpsc::Sender<()>) {
    let mut interval = interval(Duration::from_millis(SYNC_INTERVAL_IN_MILLIS));
    while sender.send(()).await.is_ok() {
        interval.tick().await;
    }
}
