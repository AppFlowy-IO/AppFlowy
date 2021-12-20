use crate::services::doc::{
    web_socket::{
        local_ws_impl::EditorLocalWebSocket,
        DocumentWSSinkDataProvider,
        DocumentWSSteamConsumer,
        EditorHttpWebSocket,
    },
    DocumentMD5,
    DocumentWebSocket,
    DocumentWsHandler,
    EditorCommand,
    RevisionManager,
    TransformDeltas,
};
use bytes::Bytes;
use flowy_collaboration::{
    entities::ws::{DocumentWSData, DocumentWSDataBuilder, DocumentWSDataType, NewDocumentUser},
    errors::CollaborateResult,
};
use flowy_error::{internal_error, FlowyError, FlowyResult};
use lib_infra::future::FutureResult;
use lib_ot::revision::{RevType, Revision, RevisionRange};
use lib_ws::WSConnectState;
use std::{collections::VecDeque, sync::Arc};
use tokio::sync::{broadcast, mpsc::UnboundedSender, oneshot, RwLock};

pub(crate) trait EditorWebSocket: Send + Sync {
    fn stop_web_socket(&self);
    fn ws_handler(&self) -> Arc<dyn DocumentWsHandler>;
}

pub(crate) struct DocumentWebSocketContext {
    pub(crate) doc_id: String,
    pub(crate) user_id: String,
    pub(crate) editor_cmd_sender: UnboundedSender<EditorCommand>,
    pub(crate) rev_manager: Arc<RevisionManager>,
    pub(crate) ws: Arc<dyn DocumentWebSocket>,
}

pub(crate) async fn initialize_document_web_socket(ctx: DocumentWebSocketContext) -> Arc<dyn EditorWebSocket> {
    if cfg!(feature = "http_server") {
        let combined_sink = Arc::new(CombinedSink::new(ctx.rev_manager.clone()));
        let ws_stream_consumer = Arc::new(DocumentWebSocketSteamConsumerAdapter {
            doc_id: ctx.doc_id.clone(),
            user_id: ctx.user_id.clone(),
            editor_cmd_sender: ctx.editor_cmd_sender.clone(),
            rev_manager: ctx.rev_manager.clone(),
            combined_sink: combined_sink.clone(),
        });
        let ws_stream_provider = DocumentWSSinkDataProviderAdapter(combined_sink.clone());
        let editor_ws = Arc::new(EditorHttpWebSocket::new(
            &ctx.doc_id,
            ctx.ws.clone(),
            Arc::new(ws_stream_provider),
            ws_stream_consumer,
        ));

        notify_user_conn(
            &ctx.user_id,
            &ctx.doc_id,
            ctx.rev_manager.clone(),
            combined_sink.clone(),
        )
        .await;

        listen_document_ws_state(
            &ctx.user_id,
            &ctx.doc_id,
            editor_ws.scribe_state(),
            ctx.rev_manager.clone(),
            combined_sink,
        );

        Arc::new(editor_ws)
    } else {
        Arc::new(Arc::new(EditorLocalWebSocket {}))
    }
}

async fn notify_user_conn(
    user_id: &str,
    doc_id: &str,
    rev_manager: Arc<RevisionManager>,
    combined_sink: Arc<CombinedSink>,
) {
    let need_notify = match combined_sink.front().await {
        None => true,
        Some(data) => data.ty != DocumentWSDataType::UserConnect,
    };

    if need_notify {
        let new_connect = NewDocumentUser {
            user_id: user_id.to_owned(),
            doc_id: doc_id.to_owned(),
            rev_id: rev_manager.latest_rev_id(),
        };

        let data = DocumentWSDataBuilder::build_new_document_user_message(doc_id, new_connect);
        combined_sink.push_front(data).await;
    }
}

fn listen_document_ws_state(
    user_id: &str,
    doc_id: &str,
    mut subscriber: broadcast::Receiver<WSConnectState>,
    rev_manager: Arc<RevisionManager>,
    sink_data_provider: Arc<CombinedSink>,
) {
    let user_id = user_id.to_owned();
    let doc_id = doc_id.to_owned();

    tokio::spawn(async move {
        while let Ok(state) = subscriber.recv().await {
            match state {
                WSConnectState::Init => {},
                WSConnectState::Connecting => {},
                WSConnectState::Connected => {
                    // self.notify_user_conn()
                    notify_user_conn(&user_id, &doc_id, rev_manager.clone(), sink_data_provider.clone()).await;
                },
                WSConnectState::Disconnected => {},
            }
        }
    });
}

pub(crate) struct DocumentWebSocketSteamConsumerAdapter {
    pub(crate) doc_id: String,
    pub(crate) user_id: String,
    pub(crate) editor_cmd_sender: UnboundedSender<EditorCommand>,
    pub(crate) rev_manager: Arc<RevisionManager>,
    pub(crate) combined_sink: Arc<CombinedSink>,
}

impl DocumentWSSteamConsumer for DocumentWebSocketSteamConsumerAdapter {
    fn receive_push_revision(&self, bytes: Bytes) -> FutureResult<(), FlowyError> {
        let user_id = self.user_id.clone();
        let rev_manager = self.rev_manager.clone();
        let edit_cmd_tx = self.editor_cmd_sender.clone();
        let combined_sink = self.combined_sink.clone();
        let doc_id = self.doc_id.clone();
        FutureResult::new(async move {
            if let Some(revision) = handle_push_rev(&doc_id, &user_id, edit_cmd_tx, rev_manager, bytes).await? {
                combined_sink.push_back(revision.into()).await;
            }
            Ok(())
        })
    }

    fn receive_ack(&self, id: String, ty: DocumentWSDataType) -> FutureResult<(), FlowyError> {
        let combined_sink = self.combined_sink.clone();
        FutureResult::new(async move { combined_sink.ack(id, ty).await })
    }

    fn receive_new_user_connect(&self, _new_user: NewDocumentUser) -> FutureResult<(), FlowyError> {
        FutureResult::new(async move { Ok(()) })
    }

    fn send_revision_in_range(&self, range: RevisionRange) -> FutureResult<(), FlowyError> {
        let rev_manager = self.rev_manager.clone();
        let combined_sink = self.combined_sink.clone();
        FutureResult::new(async move {
            let revision = rev_manager.mk_revisions(range).await?;
            combined_sink.push_back(revision.into()).await;
            Ok(())
        })
    }
}

pub(crate) struct DocumentWSSinkDataProviderAdapter(pub(crate) Arc<CombinedSink>);
impl DocumentWSSinkDataProvider for DocumentWSSinkDataProviderAdapter {
    fn next(&self) -> FutureResult<Option<DocumentWSData>, FlowyError> {
        let combined_sink = self.0.clone();
        FutureResult::new(async move { combined_sink.next().await })
    }
}

#[tracing::instrument(level = "debug", skip(edit_cmd_tx, rev_manager, bytes))]
pub(crate) async fn handle_push_rev(
    doc_id: &str,
    user_id: &str,
    edit_cmd_tx: UnboundedSender<EditorCommand>,
    rev_manager: Arc<RevisionManager>,
    bytes: Bytes,
) -> FlowyResult<Option<Revision>> {
    // Transform the revision
    let (ret, rx) = oneshot::channel::<CollaborateResult<TransformDeltas>>();
    let _ = edit_cmd_tx.send(EditorCommand::ProcessRemoteRevision { bytes, ret });
    let TransformDeltas {
        client_prime,
        server_prime,
        server_rev_id,
    } = rx.await.map_err(internal_error)??;

    if rev_manager.rev_id() >= server_rev_id.value {
        // Ignore this push revision if local_rev_id >= server_rev_id
        return Ok(None);
    }

    // compose delta
    let (ret, rx) = oneshot::channel::<CollaborateResult<DocumentMD5>>();
    let msg = EditorCommand::ComposeDelta {
        delta: client_prime.clone(),
        ret,
    };
    let _ = edit_cmd_tx.send(msg);
    let md5 = rx.await.map_err(internal_error)??;

    // update rev id
    rev_manager.update_rev_id_counter_value(server_rev_id.clone().into());
    let (local_base_rev_id, local_rev_id) = rev_manager.next_rev_id();
    let delta_data = client_prime.to_bytes();
    // save the revision
    let revision = Revision::new(
        &doc_id,
        local_base_rev_id,
        local_rev_id,
        delta_data,
        RevType::Remote,
        &user_id,
        md5.clone(),
    );

    let _ = rev_manager.add_remote_revision(&revision).await?;

    // send the server_prime delta
    let delta_data = server_prime.to_bytes();
    Ok(Some(Revision::new(
        &doc_id,
        local_base_rev_id,
        local_rev_id,
        delta_data,
        RevType::Remote,
        &user_id,
        md5,
    )))
}

#[derive(Clone)]
enum SourceType {
    Shared,
    Revision,
}

#[derive(Clone)]
pub(crate) struct CombinedSink {
    shared: Arc<RwLock<VecDeque<DocumentWSData>>>,
    rev_manager: Arc<RevisionManager>,
    source_ty: Arc<RwLock<SourceType>>,
}

impl CombinedSink {
    pub(crate) fn new(rev_manager: Arc<RevisionManager>) -> Self {
        CombinedSink {
            shared: Arc::new(RwLock::new(VecDeque::new())),
            rev_manager,
            source_ty: Arc::new(RwLock::new(SourceType::Shared)),
        }
    }

    // FIXME: return Option<&DocumentWSData> would be better
    pub(crate) async fn front(&self) -> Option<DocumentWSData> { self.shared.read().await.front().cloned() }

    pub(crate) async fn push_front(&self, data: DocumentWSData) { self.shared.write().await.push_front(data); }

    async fn push_back(&self, data: DocumentWSData) { self.shared.write().await.push_back(data); }

    async fn next(&self) -> FlowyResult<Option<DocumentWSData>> {
        let source_ty = self.source_ty.read().await.clone();
        match source_ty {
            SourceType::Shared => match self.shared.read().await.front() {
                None => {
                    *self.source_ty.write().await = SourceType::Revision;
                    Ok(None)
                },
                Some(data) => {
                    tracing::debug!("[DocumentSinkDataProvider]: {}:{:?}", data.doc_id, data.ty);
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
                        tracing::debug!("[DocumentSinkDataProvider]: {}:{:?}", rev.doc_id, rev.rev_id);
                        Ok(Some(rev.into()))
                    },
                    None => Ok(None),
                }
            },
        }
    }

    async fn ack(&self, id: String, _ty: DocumentWSDataType) -> FlowyResult<()> {
        // let _ = self.rev_manager.ack_revision(id).await?;
        let source_ty = self.source_ty.read().await.clone();
        match source_ty {
            SourceType::Shared => {
                let should_pop = match self.shared.read().await.front() {
                    None => false,
                    Some(val) => {
                        if val.id == id {
                            true
                        } else {
                            tracing::error!("The front element's {} is not equal to the {}", val.id, id);
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
