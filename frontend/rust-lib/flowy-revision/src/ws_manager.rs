use crate::ConflictRevisionSink;
use async_stream::stream;

use bytes::Bytes;
use flowy_error::{FlowyError, FlowyResult};
use flowy_sync::entities::{
    revision::{RevId, Revision, RevisionRange},
    ws_data::{ClientRevisionWSData, NewDocumentUser, ServerRevisionWSData, ServerRevisionWSDataType},
};
use futures_util::{future::BoxFuture, stream::StreamExt};
use lib_infra::future::{BoxResultFuture, FutureResult};
use lib_ws::WSConnectState;
use std::{collections::VecDeque, convert::TryFrom, fmt::Formatter, sync::Arc};
use tokio::{
    sync::{
        broadcast, mpsc,
        mpsc::{Receiver, Sender},
        RwLock,
    },
    time::{interval, Duration},
};

// The consumer consumes the messages pushed by the web socket.
pub trait RevisionWSDataStream: Send + Sync {
    fn receive_push_revision(&self, bytes: Bytes) -> BoxResultFuture<(), FlowyError>;
    fn receive_ack(&self, id: String, ty: ServerRevisionWSDataType) -> BoxResultFuture<(), FlowyError>;
    fn receive_new_user_connect(&self, new_user: NewDocumentUser) -> BoxResultFuture<(), FlowyError>;
    fn pull_revisions_in_range(&self, range: RevisionRange) -> BoxResultFuture<(), FlowyError>;
}

// The sink provides the data that will be sent through the web socket to the
// backend.
pub trait RevisionWebSocketSink: Send + Sync {
    fn next(&self) -> FutureResult<Option<ClientRevisionWSData>, FlowyError>;
}

pub type WSStateReceiver = tokio::sync::broadcast::Receiver<WSConnectState>;
pub trait RevisionWebSocket: Send + Sync + 'static {
    fn send(&self, data: ClientRevisionWSData) -> BoxResultFuture<(), FlowyError>;
    fn subscribe_state_changed(&self) -> BoxFuture<WSStateReceiver>;
}

pub struct RevisionWebSocketManager {
    pub object_name: String,
    pub object_id: String,
    ws_data_sink: Arc<dyn RevisionWebSocketSink>,
    ws_data_stream: Arc<dyn RevisionWSDataStream>,
    rev_web_socket: Arc<dyn RevisionWebSocket>,
    pub ws_passthrough_tx: Sender<ServerRevisionWSData>,
    ws_passthrough_rx: Option<Receiver<ServerRevisionWSData>>,
    pub state_passthrough_tx: broadcast::Sender<WSConnectState>,
    stop_sync_tx: SinkStopTx,
}

impl std::fmt::Display for RevisionWebSocketManager {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_fmt(format_args!("{}RevisionWebSocketManager", self.object_name))
    }
}
impl RevisionWebSocketManager {
    pub fn new(
        object_name: &str,
        object_id: &str,
        rev_web_socket: Arc<dyn RevisionWebSocket>,
        ws_data_sink: Arc<dyn RevisionWebSocketSink>,
        ws_data_stream: Arc<dyn RevisionWSDataStream>,
        ping_duration: Duration,
    ) -> Self {
        let (ws_passthrough_tx, ws_passthrough_rx) = mpsc::channel(1000);
        let (stop_sync_tx, _) = tokio::sync::broadcast::channel(2);
        let object_id = object_id.to_string();
        let object_name = object_name.to_string();
        let (state_passthrough_tx, _) = broadcast::channel(2);
        let mut manager = RevisionWebSocketManager {
            object_id,
            object_name,
            ws_data_sink,
            ws_data_stream,
            rev_web_socket,
            ws_passthrough_tx,
            ws_passthrough_rx: Some(ws_passthrough_rx),
            state_passthrough_tx,
            stop_sync_tx,
        };
        manager.run(ping_duration);
        manager
    }

    fn run(&mut self, ping_duration: Duration) {
        let ws_passthrough_rx = self.ws_passthrough_rx.take().expect("Only take once");
        let sink = RevisionWSSink::new(
            &self.object_id,
            &self.object_name,
            self.ws_data_sink.clone(),
            self.rev_web_socket.clone(),
            self.stop_sync_tx.subscribe(),
            ping_duration,
        );
        let stream = RevisionWSStream::new(
            &self.object_name,
            &self.object_id,
            self.ws_data_stream.clone(),
            ws_passthrough_rx,
            self.stop_sync_tx.subscribe(),
        );
        tokio::spawn(sink.run());
        tokio::spawn(stream.run());
    }

    pub fn scribe_state(&self) -> broadcast::Receiver<WSConnectState> {
        self.state_passthrough_tx.subscribe()
    }

    pub fn stop(&self) {
        if self.stop_sync_tx.send(()).is_ok() {
            tracing::trace!("{} stop sync", self.object_id)
        }
    }

    #[tracing::instrument(level = "debug", skip(self, data), err)]
    pub async fn receive_ws_data(&self, data: ServerRevisionWSData) -> Result<(), FlowyError> {
        let _ = self.ws_passthrough_tx.send(data).await.map_err(|e| {
            let err_msg = format!("{} passthrough error: {}", self.object_id, e);
            FlowyError::internal().context(err_msg)
        })?;
        Ok(())
    }

    pub fn connect_state_changed(&self, state: WSConnectState) {
        match self.state_passthrough_tx.send(state) {
            Ok(_) => {}
            Err(e) => tracing::error!("{}", e),
        }
    }
}

impl std::ops::Drop for RevisionWebSocketManager {
    fn drop(&mut self) {
        tracing::trace!("{} was dropped", self)
    }
}

pub struct RevisionWSStream {
    object_name: String,
    object_id: String,
    consumer: Arc<dyn RevisionWSDataStream>,
    ws_msg_rx: Option<mpsc::Receiver<ServerRevisionWSData>>,
    stop_rx: Option<SinkStopRx>,
}

impl std::fmt::Display for RevisionWSStream {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_fmt(format_args!("{}RevisionWSStream", self.object_name))
    }
}

impl std::ops::Drop for RevisionWSStream {
    fn drop(&mut self) {
        tracing::trace!("{} was dropped", self)
    }
}

impl RevisionWSStream {
    pub fn new(
        object_name: &str,
        object_id: &str,
        consumer: Arc<dyn RevisionWSDataStream>,
        ws_msg_rx: mpsc::Receiver<ServerRevisionWSData>,
        stop_rx: SinkStopRx,
    ) -> Self {
        RevisionWSStream {
            object_name: object_name.to_string(),
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
        let name = format!("{}", &self);
        let stream = stream! {
            loop {
                tokio::select! {
                    result = receiver.recv() => {
                        match result {
                            Some(msg) => {
                                yield msg
                            },
                            None => {
                                tracing::debug!("[{}]:{} loop exit", name, object_id);
                                break;
                            },
                        }
                    },
                    _ = stop_rx.recv() => {
                        tracing::debug!("[{}]:{} loop exit", name, object_id);
                        break
                    },
                };
            }
        };

        stream
            .for_each(|msg| async {
                match self.handle_message(msg).await {
                    Ok(_) => {}
                    Err(e) => tracing::error!("[{}]:{} error: {}", &self, self.object_id, e),
                }
            })
            .await;
    }

    async fn handle_message(&self, msg: ServerRevisionWSData) -> FlowyResult<()> {
        let ServerRevisionWSData { object_id, ty, data } = msg;
        let bytes = Bytes::from(data);
        match ty {
            ServerRevisionWSDataType::ServerPushRev => {
                tracing::trace!("[{}]: new push revision: {}:{:?}", self, object_id, ty);
                let _ = self.consumer.receive_push_revision(bytes).await?;
            }
            ServerRevisionWSDataType::ServerPullRev => {
                let range = RevisionRange::try_from(bytes)?;
                tracing::trace!("[{}]: new pull: {}:{}-{:?}", self, object_id, range, ty);
                let _ = self.consumer.pull_revisions_in_range(range).await?;
            }
            ServerRevisionWSDataType::ServerAck => {
                let rev_id = RevId::try_from(bytes).unwrap().value;
                tracing::trace!("[{}]: new ack: {}:{}-{:?}", self, object_id, rev_id, ty);
                let _ = self.consumer.receive_ack(rev_id.to_string(), ty).await;
            }
            ServerRevisionWSDataType::UserConnect => {
                let new_user = NewDocumentUser::try_from(bytes)?;
                let _ = self.consumer.receive_new_user_connect(new_user).await;
            }
        }
        Ok(())
    }
}

type SinkStopRx = broadcast::Receiver<()>;
type SinkStopTx = broadcast::Sender<()>;
pub struct RevisionWSSink {
    object_id: String,
    object_name: String,
    provider: Arc<dyn RevisionWebSocketSink>,
    rev_web_socket: Arc<dyn RevisionWebSocket>,
    stop_rx: Option<SinkStopRx>,
    ping_duration: Duration,
}

impl RevisionWSSink {
    pub fn new(
        object_id: &str,
        object_name: &str,
        provider: Arc<dyn RevisionWebSocketSink>,
        rev_web_socket: Arc<dyn RevisionWebSocket>,
        stop_rx: SinkStopRx,
        ping_duration: Duration,
    ) -> Self {
        Self {
            object_id: object_id.to_owned(),
            object_name: object_name.to_owned(),
            provider,
            rev_web_socket,
            stop_rx: Some(stop_rx),
            ping_duration,
        }
    }

    pub async fn run(mut self) {
        let (tx, mut rx) = mpsc::channel(1);
        let mut stop_rx = self.stop_rx.take().expect("Only take once");
        let object_id = self.object_id.clone();
        tokio::spawn(tick(tx, self.ping_duration));
        let name = format!("{}", self);
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
                        tracing::trace!("[{}]:{} loop exit", name, object_id);
                        break
                    },
                };
            }
        };
        stream
            .for_each(|_| async {
                match self.send_next_revision().await {
                    Ok(_) => {}
                    Err(e) => tracing::error!("[{}] send failed, {:?}", self, e),
                }
            })
            .await;
    }

    async fn send_next_revision(&self) -> FlowyResult<()> {
        match self.provider.next().await? {
            None => {
                tracing::trace!("[{}]: Finish synchronizing revisions", self);
                Ok(())
            }
            Some(data) => {
                tracing::trace!("[{}]: send {}:{}-{:?}", self, data.object_id, data.id(), data.ty);
                self.rev_web_socket.send(data).await
            }
        }
    }
}

async fn tick(sender: mpsc::Sender<()>, duration: Duration) {
    let mut interval = interval(duration);
    while sender.send(()).await.is_ok() {
        interval.tick().await;
    }
}

impl std::fmt::Display for RevisionWSSink {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_fmt(format_args!("{}RevisionWSSink", self.object_name))
    }
}

impl std::ops::Drop for RevisionWSSink {
    fn drop(&mut self) {
        tracing::trace!("{} was dropped", self)
    }
}

#[derive(Clone)]
enum Source {
    Custom,
    Revision,
}

pub trait WSDataProviderDataSource: Send + Sync {
    fn next_revision(&self) -> FutureResult<Option<Revision>, FlowyError>;
    fn ack_revision(&self, rev_id: i64) -> FutureResult<(), FlowyError>;
    fn current_rev_id(&self) -> i64;
}

#[derive(Clone)]
pub struct WSDataProvider {
    object_id: String,
    rev_ws_data_list: Arc<RwLock<VecDeque<ClientRevisionWSData>>>,
    data_source: Arc<dyn WSDataProviderDataSource>,
    current_source: Arc<RwLock<Source>>,
}

impl WSDataProvider {
    pub fn new(object_id: &str, data_source: Arc<dyn WSDataProviderDataSource>) -> Self {
        WSDataProvider {
            object_id: object_id.to_owned(),
            rev_ws_data_list: Arc::new(RwLock::new(VecDeque::new())),
            data_source,
            current_source: Arc::new(RwLock::new(Source::Custom)),
        }
    }

    pub async fn push_data(&self, data: ClientRevisionWSData) {
        self.rev_ws_data_list.write().await.push_back(data);
    }

    pub async fn next(&self) -> FlowyResult<Option<ClientRevisionWSData>> {
        let source = self.current_source.read().await.clone();
        let data = match source {
            Source::Custom => match self.rev_ws_data_list.read().await.front() {
                None => {
                    *self.current_source.write().await = Source::Revision;
                    Ok(None)
                }
                Some(data) => Ok(Some(data.clone())),
            },
            Source::Revision => {
                if !self.rev_ws_data_list.read().await.is_empty() {
                    *self.current_source.write().await = Source::Custom;
                    return Ok(None);
                }

                match self.data_source.next_revision().await? {
                    Some(rev) => Ok(Some(ClientRevisionWSData::from_revisions(&self.object_id, vec![rev]))),
                    None => Ok(Some(ClientRevisionWSData::ping(
                        &self.object_id,
                        self.data_source.current_rev_id(),
                    ))),
                }
            }
        };
        data
    }

    pub async fn ack_data(&self, id: String, _ty: ServerRevisionWSDataType) -> FlowyResult<()> {
        let source = self.current_source.read().await.clone();
        match source {
            Source::Custom => {
                let should_pop = match self.rev_ws_data_list.read().await.front() {
                    None => false,
                    Some(val) => {
                        let expected_id = val.id();
                        if expected_id == id {
                            true
                        } else {
                            tracing::error!("The front element's {} is not equal to the {}", expected_id, id);
                            false
                        }
                    }
                };
                if should_pop {
                    let _ = self.rev_ws_data_list.write().await.pop_front();
                }
                Ok(())
            }
            Source::Revision => {
                let rev_id = id.parse::<i64>().map_err(|e| {
                    FlowyError::internal().context(format!("Parse {} rev_id from {} failed. {}", self.object_id, id, e))
                })?;
                let _ = self.data_source.ack_revision(rev_id).await?;
                Ok::<(), FlowyError>(())
            }
        }
    }
}

impl ConflictRevisionSink for Arc<WSDataProvider> {
    fn send(&self, revisions: Vec<Revision>) -> BoxResultFuture<(), FlowyError> {
        let sink = self.clone();
        Box::pin(async move {
            sink.push_data(ClientRevisionWSData::from_revisions(&sink.object_id, revisions))
                .await;
            Ok(())
        })
    }

    fn ack(&self, rev_id: String, ty: ServerRevisionWSDataType) -> BoxResultFuture<(), FlowyError> {
        let sink = self.clone();
        Box::pin(async move { sink.ack_data(rev_id, ty).await })
    }
}
