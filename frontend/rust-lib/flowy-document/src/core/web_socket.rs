use crate::{
    core::{EditorCommand, TransformDeltas, SYNC_INTERVAL_IN_MILLIS},
    DocumentWSReceiver,
};
use async_trait::async_trait;
use bytes::Bytes;
use flowy_collaboration::{
    entities::{
        revision::{RepeatedRevision, Revision, RevisionRange},
        ws_data::{ClientRevisionWSData, NewDocumentUser, ServerRevisionWSData, ServerRevisionWSDataType},
    },
    errors::CollaborateResult,
};
use flowy_error::{internal_error, FlowyError, FlowyResult};
use flowy_sync::{
    RevisionManager,
    RevisionWSSinkDataProvider,
    RevisionWSSteamConsumer,
    RevisionWebSocket,
    RevisionWebSocketManager,
};
use lib_infra::future::FutureResult;
use lib_ws::WSConnectState;
use std::{collections::VecDeque, convert::TryFrom, sync::Arc, time::Duration};
use tokio::sync::{
    broadcast,
    mpsc::{Receiver, Sender},
    oneshot,
    RwLock,
};

pub(crate) type EditorCommandSender = Sender<EditorCommand>;
pub(crate) type EditorCommandReceiver = Receiver<EditorCommand>;

pub(crate) async fn make_document_ws_manager(
    doc_id: String,
    user_id: String,
    edit_cmd_tx: EditorCommandSender,
    rev_manager: Arc<RevisionManager>,
    web_socket: Arc<dyn RevisionWebSocket>,
) -> Arc<RevisionWebSocketManager> {
    let shared_sink = Arc::new(SharedWSSinkDataProvider::new(rev_manager.clone()));
    let ws_stream_consumer = Arc::new(DocumentWebSocketSteamConsumerAdapter {
        object_id: doc_id.clone(),
        edit_cmd_tx,
        rev_manager: rev_manager.clone(),
        shared_sink: shared_sink.clone(),
    });
    let data_provider = Arc::new(DocumentWSSinkDataProviderAdapter(shared_sink));
    let ping_duration = Duration::from_millis(SYNC_INTERVAL_IN_MILLIS);
    let ws_manager = Arc::new(RevisionWebSocketManager::new(
        &doc_id,
        web_socket,
        data_provider,
        ws_stream_consumer,
        ping_duration,
    ));
    listen_document_ws_state(&user_id, &doc_id, ws_manager.scribe_state(), rev_manager);
    ws_manager
}

fn listen_document_ws_state(
    _user_id: &str,
    _doc_id: &str,
    mut subscriber: broadcast::Receiver<WSConnectState>,
    _rev_manager: Arc<RevisionManager>,
) {
    tokio::spawn(async move {
        while let Ok(state) = subscriber.recv().await {
            match state {
                WSConnectState::Init => {},
                WSConnectState::Connecting => {},
                WSConnectState::Connected => {},
                WSConnectState::Disconnected => {},
            }
        }
    });
}

pub(crate) struct DocumentWebSocketSteamConsumerAdapter {
    pub(crate) object_id: String,
    pub(crate) edit_cmd_tx: EditorCommandSender,
    pub(crate) rev_manager: Arc<RevisionManager>,
    pub(crate) shared_sink: Arc<SharedWSSinkDataProvider>,
}

impl RevisionWSSteamConsumer for DocumentWebSocketSteamConsumerAdapter {
    fn receive_push_revision(&self, bytes: Bytes) -> FutureResult<(), FlowyError> {
        let rev_manager = self.rev_manager.clone();
        let edit_cmd_tx = self.edit_cmd_tx.clone();
        let shared_sink = self.shared_sink.clone();
        let object_id = self.object_id.clone();
        FutureResult::new(async move {
            if let Some(server_composed_revision) = handle_remote_revision(edit_cmd_tx, rev_manager, bytes).await? {
                let data = ClientRevisionWSData::from_revisions(&object_id, vec![server_composed_revision]);
                shared_sink.push_back(data).await;
            }
            Ok(())
        })
    }

    fn receive_ack(&self, id: String, ty: ServerRevisionWSDataType) -> FutureResult<(), FlowyError> {
        let shared_sink = self.shared_sink.clone();
        FutureResult::new(async move { shared_sink.ack(id, ty).await })
    }

    fn receive_new_user_connect(&self, _new_user: NewDocumentUser) -> FutureResult<(), FlowyError> {
        // Do nothing by now, just a placeholder for future extension.
        FutureResult::new(async move { Ok(()) })
    }

    fn pull_revisions_in_range(&self, range: RevisionRange) -> FutureResult<(), FlowyError> {
        let rev_manager = self.rev_manager.clone();
        let shared_sink = self.shared_sink.clone();
        let object_id = self.object_id.clone();
        FutureResult::new(async move {
            let revisions = rev_manager.get_revisions_in_range(range).await?;
            let data = ClientRevisionWSData::from_revisions(&object_id, revisions);
            shared_sink.push_back(data).await;
            Ok(())
        })
    }
}

pub(crate) struct DocumentWSSinkDataProviderAdapter(pub(crate) Arc<SharedWSSinkDataProvider>);
impl RevisionWSSinkDataProvider for DocumentWSSinkDataProviderAdapter {
    fn next(&self) -> FutureResult<Option<ClientRevisionWSData>, FlowyError> {
        let shared_sink = self.0.clone();
        FutureResult::new(async move { shared_sink.next().await })
    }
}

async fn transform_pushed_revisions(
    revisions: Vec<Revision>,
    edit_cmd: &EditorCommandSender,
) -> FlowyResult<TransformDeltas> {
    let (ret, rx) = oneshot::channel::<CollaborateResult<TransformDeltas>>();
    let _ = edit_cmd.send(EditorCommand::TransformRevision { revisions, ret });
    Ok(rx.await.map_err(internal_error)??)
}

#[tracing::instrument(level = "debug", skip(edit_cmd_tx, rev_manager, bytes))]
pub(crate) async fn handle_remote_revision(
    edit_cmd_tx: EditorCommandSender,
    rev_manager: Arc<RevisionManager>,
    bytes: Bytes,
) -> FlowyResult<Option<Revision>> {
    let mut revisions = RepeatedRevision::try_from(bytes)?.into_inner();
    if revisions.is_empty() {
        return Ok(None);
    }

    let first_revision = revisions.first().unwrap();
    if let Some(local_revision) = rev_manager.get_revision(first_revision.rev_id).await {
        if local_revision.md5 == first_revision.md5 {
            // The local revision is equal to the pushed revision. Just ignore it.
            revisions = revisions.split_off(1);
            if revisions.is_empty() {
                return Ok(None);
            }
        } else {
            return Ok(None);
        }
    }

    let TransformDeltas {
        client_prime,
        server_prime,
    } = transform_pushed_revisions(revisions.clone(), &edit_cmd_tx).await?;

    match server_prime {
        None => {
            // The server_prime is None means the client local revisions conflict with the
            // server, and it needs to override the client delta.
            let (ret, rx) = oneshot::channel();
            let _ = edit_cmd_tx.send(EditorCommand::OverrideDelta {
                revisions,
                delta: client_prime,
                ret,
            });
            let _ = rx.await.map_err(internal_error)??;
            Ok(None)
        },
        Some(server_prime) => {
            let (ret, rx) = oneshot::channel();
            let _ = edit_cmd_tx.send(EditorCommand::ComposeRemoteDelta {
                revisions,
                client_delta: client_prime,
                server_delta: server_prime,
                ret,
            });
            Ok(rx.await.map_err(internal_error)??)
        },
    }
}

#[derive(Clone)]
enum SourceType {
    Shared,
    Revision,
}

#[derive(Clone)]
pub(crate) struct SharedWSSinkDataProvider {
    shared: Arc<RwLock<VecDeque<ClientRevisionWSData>>>,
    rev_manager: Arc<RevisionManager>,
    source_ty: Arc<RwLock<SourceType>>,
}

impl SharedWSSinkDataProvider {
    pub(crate) fn new(rev_manager: Arc<RevisionManager>) -> Self {
        SharedWSSinkDataProvider {
            shared: Arc::new(RwLock::new(VecDeque::new())),
            rev_manager,
            source_ty: Arc::new(RwLock::new(SourceType::Shared)),
        }
    }

    #[allow(dead_code)]
    pub(crate) async fn push_front(&self, data: ClientRevisionWSData) { self.shared.write().await.push_front(data); }

    async fn push_back(&self, data: ClientRevisionWSData) { self.shared.write().await.push_back(data); }

    async fn next(&self) -> FlowyResult<Option<ClientRevisionWSData>> {
        let source_ty = self.source_ty.read().await.clone();
        match source_ty {
            SourceType::Shared => match self.shared.read().await.front() {
                None => {
                    *self.source_ty.write().await = SourceType::Revision;
                    Ok(None)
                },
                Some(data) => {
                    tracing::debug!("[SharedWSSinkDataProvider]: {}:{:?}", data.object_id, data.ty);
                    Ok(Some(data.clone()))
                },
            },
            SourceType::Revision => {
                if !self.shared.read().await.is_empty() {
                    *self.source_ty.write().await = SourceType::Shared;
                    return Ok(None);
                }

                match self.rev_manager.next_sync_revision().await? {
                    Some(rev) => {
                        let doc_id = rev.object_id.clone();
                        Ok(Some(ClientRevisionWSData::from_revisions(&doc_id, vec![rev])))
                    },
                    None => {
                        //
                        let doc_id = self.rev_manager.object_id.clone();
                        let latest_rev_id = self.rev_manager.rev_id();
                        Ok(Some(ClientRevisionWSData::ping(&doc_id, latest_rev_id)))
                    },
                }
            },
        }
    }

    async fn ack(&self, id: String, _ty: ServerRevisionWSDataType) -> FlowyResult<()> {
        // let _ = self.rev_manager.ack_revision(id).await?;
        let source_ty = self.source_ty.read().await.clone();
        match source_ty {
            SourceType::Shared => {
                let should_pop = match self.shared.read().await.front() {
                    None => false,
                    Some(val) => {
                        let expected_id = val.id();
                        if expected_id == id {
                            true
                        } else {
                            tracing::error!("The front element's {} is not equal to the {}", expected_id, id);
                            false
                        }
                    },
                };
                if should_pop {
                    let _ = self.shared.write().await.pop_front();
                }
            },
            SourceType::Revision => {
                match id.parse::<i64>() {
                    Ok(rev_id) => {
                        let _ = self.rev_manager.ack_revision(rev_id).await?;
                    },
                    Err(e) => {
                        tracing::error!("Parse rev_id from {} failed. {}", id, e);
                    },
                };
            },
        }

        Ok(())
    }
}

//  RevisionWebSocketManager registers itself as a DocumentWSReceiver for each
//  opened document.
#[async_trait]
impl DocumentWSReceiver for RevisionWebSocketManager {
    #[tracing::instrument(level = "debug", skip(self, data), err)]
    async fn receive_ws_data(&self, data: ServerRevisionWSData) -> Result<(), FlowyError> {
        let _ = self.ws_passthrough_tx.send(data).await.map_err(|e| {
            let err_msg = format!("{} passthrough error: {}", self.object_id, e);
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
