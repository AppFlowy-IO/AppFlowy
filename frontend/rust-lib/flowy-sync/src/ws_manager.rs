use async_stream::stream;
use bytes::Bytes;
use flowy_collaboration::entities::{
    revision::{RevId, RevisionRange},
    ws::{ClientRevisionWSData, NewDocumentUser, ServerRevisionWSData, ServerRevisionWSDataType},
};
use flowy_error::{internal_error, FlowyError, FlowyResult};
use futures_util::stream::StreamExt;
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
pub trait RevisionWSSteamConsumer: Send + Sync {
    fn receive_push_revision(&self, bytes: Bytes) -> FutureResult<(), FlowyError>;
    fn receive_ack(&self, id: String, ty: ServerRevisionWSDataType) -> FutureResult<(), FlowyError>;
    fn receive_new_user_connect(&self, new_user: NewDocumentUser) -> FutureResult<(), FlowyError>;
    fn pull_revisions_in_range(&self, range: RevisionRange) -> FutureResult<(), FlowyError>;
}

// The sink provides the data that will be sent through the web socket to the
// backend.
pub trait RevisionWSSinkDataProvider: Send + Sync {
    fn next(&self) -> FutureResult<Option<ClientRevisionWSData>, FlowyError>;
}

pub type WSStateReceiver = tokio::sync::broadcast::Receiver<WSConnectState>;
pub trait RevisionWebSocket: Send + Sync {
    fn send(&self, data: ClientRevisionWSData) -> Result<(), FlowyError>;
    fn subscribe_state_changed(&self) -> WSStateReceiver;
}

pub struct RevisionWebSocketManager {
    pub object_id: String,
    data_provider: Arc<dyn RevisionWSSinkDataProvider>,
    stream_consumer: Arc<dyn RevisionWSSteamConsumer>,
    web_socket: Arc<dyn RevisionWebSocket>,
    pub ws_passthrough_tx: Sender<ServerRevisionWSData>,
    ws_passthrough_rx: Option<Receiver<ServerRevisionWSData>>,
    pub state_passthrough_tx: broadcast::Sender<WSConnectState>,
    stop_sync_tx: SinkStopTx,
}

impl RevisionWebSocketManager {
    pub fn new(
        object_id: &str,
        web_socket: Arc<dyn RevisionWebSocket>,
        data_provider: Arc<dyn RevisionWSSinkDataProvider>,
        stream_consumer: Arc<dyn RevisionWSSteamConsumer>,
        ping_duration: Duration,
    ) -> Self {
        let (ws_passthrough_tx, ws_passthrough_rx) = mpsc::channel(1000);
        let (stop_sync_tx, _) = tokio::sync::broadcast::channel(2);
        let object_id = object_id.to_string();
        let (state_passthrough_tx, _) = broadcast::channel(2);
        let mut manager = RevisionWebSocketManager {
            object_id,
            data_provider,
            stream_consumer,
            web_socket,
            ws_passthrough_tx,
            ws_passthrough_rx: Some(ws_passthrough_rx),
            state_passthrough_tx,
            stop_sync_tx,
        };
        manager.run(ping_duration);
        manager
    }

    fn run(&mut self, ping_duration: Duration) {
        let ws_msg_rx = self.ws_passthrough_rx.take().expect("Only take once");
        let sink = RevisionWSSink::new(
            &self.object_id,
            self.data_provider.clone(),
            self.web_socket.clone(),
            self.stop_sync_tx.subscribe(),
            ping_duration,
        );
        let stream = RevisionWSStream::new(
            &self.object_id,
            self.stream_consumer.clone(),
            ws_msg_rx,
            self.stop_sync_tx.subscribe(),
        );
        tokio::spawn(sink.run());
        tokio::spawn(stream.run());
    }

    pub fn scribe_state(&self) -> broadcast::Receiver<WSConnectState> { self.state_passthrough_tx.subscribe() }

    pub fn stop(&self) {
        if self.stop_sync_tx.send(()).is_ok() {
            tracing::trace!("{} stop sync", self.object_id)
        }
    }
}

impl std::ops::Drop for RevisionWebSocketManager {
    fn drop(&mut self) { tracing::trace!("{} RevisionWebSocketManager was dropped", self.object_id) }
}

pub struct RevisionWSStream {
    object_id: String,
    consumer: Arc<dyn RevisionWSSteamConsumer>,
    ws_msg_rx: Option<mpsc::Receiver<ServerRevisionWSData>>,
    stop_rx: Option<SinkStopRx>,
}

impl std::ops::Drop for RevisionWSStream {
    fn drop(&mut self) { tracing::trace!("{} RevisionWSStream was dropped", self.object_id) }
}

impl RevisionWSStream {
    pub fn new(
        object_id: &str,
        consumer: Arc<dyn RevisionWSSteamConsumer>,
        ws_msg_rx: mpsc::Receiver<ServerRevisionWSData>,
        stop_rx: SinkStopRx,
    ) -> Self {
        RevisionWSStream {
            object_id: object_id.to_owned(),
            consumer,
            ws_msg_rx: Some(ws_msg_rx),
            stop_rx: Some(stop_rx),
        }
    }

    pub async fn run(mut self) {
        let mut receiver = self.ws_msg_rx.take().expect("Only take once");
        let mut stop_rx = self.stop_rx.take().expect("Only take once");
        let object_id = self.object_id.clone();
        let stream = stream! {
            loop {
                tokio::select! {
                    result = receiver.recv() => {
                        match result {
                            Some(msg) => {
                                yield msg
                            },
                            None => {
                                tracing::debug!("[RevisionWSStream:{}] loop exit", object_id);
                                break;
                            },
                        }
                    },
                    _ = stop_rx.recv() => {
                        tracing::debug!("[RevisionWSStream:{}] loop exit", object_id);
                        break
                    },
                };
            }
        };

        stream
            .for_each(|msg| async {
                match self.handle_message(msg).await {
                    Ok(_) => {},
                    Err(e) => tracing::error!("[RevisionWSStream:{}] error: {}", self.object_id, e),
                }
            })
            .await;
    }

    async fn handle_message(&self, msg: ServerRevisionWSData) -> FlowyResult<()> {
        let ServerRevisionWSData { object_id: _, ty, data } = msg;
        let bytes = spawn_blocking(move || Bytes::from(data))
            .await
            .map_err(internal_error)?;

        tracing::trace!("[RevisionWSStream]: new message: {:?}", ty);
        match ty {
            ServerRevisionWSDataType::ServerPushRev => {
                let _ = self.consumer.receive_push_revision(bytes).await?;
            },
            ServerRevisionWSDataType::ServerPullRev => {
                let range = RevisionRange::try_from(bytes)?;
                let _ = self.consumer.pull_revisions_in_range(range).await?;
            },
            ServerRevisionWSDataType::ServerAck => {
                let rev_id = RevId::try_from(bytes).unwrap().value;
                let _ = self.consumer.receive_ack(rev_id.to_string(), ty).await;
            },
            ServerRevisionWSDataType::UserConnect => {
                let new_user = NewDocumentUser::try_from(bytes)?;
                let _ = self.consumer.receive_new_user_connect(new_user).await;
            },
        }
        Ok(())
    }
}

type SinkStopRx = broadcast::Receiver<()>;
type SinkStopTx = broadcast::Sender<()>;
pub struct RevisionWSSink {
    provider: Arc<dyn RevisionWSSinkDataProvider>,
    ws_sender: Arc<dyn RevisionWebSocket>,
    stop_rx: Option<SinkStopRx>,
    object_id: String,
    ping_duration: Duration,
}

impl RevisionWSSink {
    pub fn new(
        object_id: &str,
        provider: Arc<dyn RevisionWSSinkDataProvider>,
        ws_sender: Arc<dyn RevisionWebSocket>,
        stop_rx: SinkStopRx,
        ping_duration: Duration,
    ) -> Self {
        Self {
            provider,
            ws_sender,
            stop_rx: Some(stop_rx),
            object_id: object_id.to_owned(),
            ping_duration,
        }
    }

    pub async fn run(mut self) {
        let (tx, mut rx) = mpsc::channel(1);
        let mut stop_rx = self.stop_rx.take().expect("Only take once");
        let object_id = self.object_id.clone();
        tokio::spawn(tick(tx, self.ping_duration));
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
                        tracing::trace!("[RevisionWSSink:{}] loop exit", object_id);
                        break
                    },
                };
            }
        };
        stream
            .for_each(|_| async {
                match self.send_next_revision().await {
                    Ok(_) => {},
                    Err(e) => tracing::error!("[RevisionWSSink] send failed, {:?}", e),
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
                tracing::trace!("[RevisionWSSink] send: {}:{}-{:?}", data.object_id, data.id(), data.ty);
                self.ws_sender.send(data)
            },
        }
    }
}

impl std::ops::Drop for RevisionWSSink {
    fn drop(&mut self) { tracing::trace!("{} RevisionWSSink was dropped", self.object_id) }
}

async fn tick(sender: mpsc::Sender<()>, duration: Duration) {
    let mut interval = interval(duration);
    while sender.send(()).await.is_ok() {
        interval.tick().await;
    }
}
