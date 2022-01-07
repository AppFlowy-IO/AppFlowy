use crate::core::{
    web_socket::{DocumentWSSinkDataProvider, DocumentWSSteamConsumer, HttpWebSocketManager},
    DocumentWSReceiver,
    DocumentWebSocket,
    EditorCommand,
    RevisionManager,
    TransformDeltas,
};
use bytes::Bytes;
use flowy_collaboration::{
    entities::{
        revision::{RepeatedRevision, Revision, RevisionRange},
        ws::{DocumentClientWSData, NewDocumentUser},
    },
    errors::CollaborateResult,
};
use flowy_error::{internal_error, FlowyError, FlowyResult};
use lib_infra::future::FutureResult;

use crate::core::web_socket::local_ws_impl::LocalWebSocketManager;
use flowy_collaboration::entities::ws::DocumentServerWSDataType;

use lib_ws::WSConnectState;
use std::{collections::VecDeque, convert::TryFrom, sync::Arc};
use tokio::sync::{broadcast, mpsc::UnboundedSender, oneshot, RwLock};

pub(crate) trait DocumentWebSocketManager: Send + Sync {
    fn stop(&self);
    fn receiver(&self) -> Arc<dyn DocumentWSReceiver>;
}

pub(crate) async fn make_document_ws_manager(
    doc_id: String,
    user_id: String,
    edit_cmd_tx: UnboundedSender<EditorCommand>,
    rev_manager: Arc<RevisionManager>,
    ws: Arc<dyn DocumentWebSocket>,
) -> Arc<dyn DocumentWebSocketManager> {
    if cfg!(feature = "http_server") {
        let shared_sink = Arc::new(SharedWSSinkDataProvider::new(rev_manager.clone()));
        let ws_stream_consumer = Arc::new(DocumentWebSocketSteamConsumerAdapter {
            doc_id: doc_id.clone(),
            edit_cmd_tx,
            rev_manager: rev_manager.clone(),
            shared_sink: shared_sink.clone(),
        });
        let ws_stream_provider = DocumentWSSinkDataProviderAdapter(shared_sink);
        let ws_manager = Arc::new(HttpWebSocketManager::new(
            &doc_id,
            ws.clone(),
            Arc::new(ws_stream_provider),
            ws_stream_consumer,
        ));
        listen_document_ws_state(&user_id, &doc_id, ws_manager.scribe_state(), rev_manager);
        Arc::new(ws_manager)
    } else {
        Arc::new(Arc::new(LocalWebSocketManager {}))
    }
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
    pub(crate) doc_id: String,
    pub(crate) edit_cmd_tx: UnboundedSender<EditorCommand>,
    pub(crate) rev_manager: Arc<RevisionManager>,
    pub(crate) shared_sink: Arc<SharedWSSinkDataProvider>,
}

impl DocumentWSSteamConsumer for DocumentWebSocketSteamConsumerAdapter {
    fn receive_push_revision(&self, bytes: Bytes) -> FutureResult<(), FlowyError> {
        let rev_manager = self.rev_manager.clone();
        let edit_cmd_tx = self.edit_cmd_tx.clone();
        let shared_sink = self.shared_sink.clone();
        let doc_id = self.doc_id.clone();
        FutureResult::new(async move {
            if let Some(server_composed_revision) = handle_remote_revision(edit_cmd_tx, rev_manager, bytes).await? {
                let data = DocumentClientWSData::from_revisions(&doc_id, vec![server_composed_revision]);
                shared_sink.push_back(data).await;
            }
            Ok(())
        })
    }

    fn receive_ack(&self, id: String, ty: DocumentServerWSDataType) -> FutureResult<(), FlowyError> {
        let shared_sink = self.shared_sink.clone();
        FutureResult::new(async move { shared_sink.ack(id, ty).await })
    }

    fn receive_new_user_connect(&self, _new_user: NewDocumentUser) -> FutureResult<(), FlowyError> {
        // the _new_user will be used later
        FutureResult::new(async move { Ok(()) })
    }

    fn pull_revisions_in_range(&self, range: RevisionRange) -> FutureResult<(), FlowyError> {
        let rev_manager = self.rev_manager.clone();
        let shared_sink = self.shared_sink.clone();
        let doc_id = self.doc_id.clone();
        FutureResult::new(async move {
            let revisions = rev_manager.get_revisions_in_range(range).await?;
            let data = DocumentClientWSData::from_revisions(&doc_id, revisions);
            shared_sink.push_back(data).await;
            Ok(())
        })
    }
}

pub(crate) struct DocumentWSSinkDataProviderAdapter(pub(crate) Arc<SharedWSSinkDataProvider>);
impl DocumentWSSinkDataProvider for DocumentWSSinkDataProviderAdapter {
    fn next(&self) -> FutureResult<Option<DocumentClientWSData>, FlowyError> {
        let shared_sink = self.0.clone();
        FutureResult::new(async move { shared_sink.next().await })
    }
}

async fn transform_pushed_revisions(
    revisions: Vec<Revision>,
    edit_cmd: &UnboundedSender<EditorCommand>,
) -> FlowyResult<TransformDeltas> {
    let (ret, rx) = oneshot::channel::<CollaborateResult<TransformDeltas>>();
    let _ = edit_cmd.send(EditorCommand::TransformRevision { revisions, ret });
    Ok(rx.await.map_err(internal_error)??)
}

#[tracing::instrument(level = "debug", skip(edit_cmd_tx, rev_manager, bytes))]
pub(crate) async fn handle_remote_revision(
    edit_cmd_tx: UnboundedSender<EditorCommand>,
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
    shared: Arc<RwLock<VecDeque<DocumentClientWSData>>>,
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
    pub(crate) async fn push_front(&self, data: DocumentClientWSData) { self.shared.write().await.push_front(data); }

    async fn push_back(&self, data: DocumentClientWSData) { self.shared.write().await.push_back(data); }

    async fn next(&self) -> FlowyResult<Option<DocumentClientWSData>> {
        let source_ty = self.source_ty.read().await.clone();
        match source_ty {
            SourceType::Shared => match self.shared.read().await.front() {
                None => {
                    *self.source_ty.write().await = SourceType::Revision;
                    Ok(None)
                },
                Some(data) => {
                    tracing::debug!("[SharedWSSinkDataProvider]: {}:{:?}", data.doc_id, data.ty);
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
                        tracing::debug!("[SharedWSSinkDataProvider]: {}:{:?}", rev.doc_id, rev.rev_id);
                        let doc_id = rev.doc_id.clone();
                        Ok(Some(DocumentClientWSData::from_revisions(&doc_id, vec![rev])))
                    },
                    None => {
                        //
                        let doc_id = self.rev_manager.doc_id.clone();
                        let latest_rev_id = self.rev_manager.rev_id();
                        Ok(Some(DocumentClientWSData::ping(&doc_id, latest_rev_id)))
                    },
                }
            },
        }
    }

    async fn ack(&self, id: String, _ty: DocumentServerWSDataType) -> FlowyResult<()> {
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
