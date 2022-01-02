use crate::services::doc::{
    web_socket::{DocumentWSSinkDataProvider, DocumentWSSteamConsumer, HttpWebSocketManager},
    DocumentMD5,
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

use crate::services::doc::web_socket::local_ws_impl::LocalWebSocketManager;
use flowy_collaboration::entities::{revision::pair_rev_id_from_revisions, ws::DocumentServerWSDataType};
use lib_ot::rich_text::RichTextDelta;
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
    editor_edit_queue: UnboundedSender<EditorCommand>,
    rev_manager: Arc<RevisionManager>,
    ws: Arc<dyn DocumentWebSocket>,
) -> Arc<dyn DocumentWebSocketManager> {
    if cfg!(feature = "http_server") {
        let shared_sink = Arc::new(SharedWSSinkDataProvider::new(rev_manager.clone()));
        let ws_stream_consumer = Arc::new(DocumentWebSocketSteamConsumerAdapter {
            doc_id: doc_id.clone(),
            user_id: user_id.clone(),
            editor_edit_queue: editor_edit_queue.clone(),
            rev_manager: rev_manager.clone(),
            shared_sink: shared_sink.clone(),
        });
        let ws_stream_provider = DocumentWSSinkDataProviderAdapter(shared_sink.clone());
        let ws_manager = Arc::new(HttpWebSocketManager::new(
            &doc_id,
            ws.clone(),
            Arc::new(ws_stream_provider),
            ws_stream_consumer,
        ));
        notify_user_has_connected(&user_id, &doc_id, rev_manager.clone(), shared_sink).await;
        listen_document_ws_state(&user_id, &doc_id, ws_manager.scribe_state(), rev_manager.clone());

        Arc::new(ws_manager)
    } else {
        Arc::new(Arc::new(LocalWebSocketManager {}))
    }
}

async fn notify_user_has_connected(
    _user_id: &str,
    _doc_id: &str,
    _rev_manager: Arc<RevisionManager>,
    _shared_sink: Arc<SharedWSSinkDataProvider>,
) {
    // let need_notify = match shared_sink.front().await {
    //     None => true,
    //     Some(data) => data.ty != DocumentClientWSDataType::UserConnect,
    // };
    //
    // if need_notify {
    //     let revision_data: Bytes =
    // rev_manager.latest_revision().await.try_into().unwrap();
    //     let new_connect = NewDocumentUser {
    //         user_id: user_id.to_owned(),
    //         doc_id: doc_id.to_owned(),
    //         revision_data: revision_data.to_vec(),
    //     };
    //
    //     let data =
    // DocumentWSDataBuilder::build_new_document_user_message(doc_id,
    // new_connect);     shared_sink.push_front(data).await;
    // }
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
    pub(crate) user_id: String,
    pub(crate) editor_edit_queue: UnboundedSender<EditorCommand>,
    pub(crate) rev_manager: Arc<RevisionManager>,
    pub(crate) shared_sink: Arc<SharedWSSinkDataProvider>,
}

impl DocumentWSSteamConsumer for DocumentWebSocketSteamConsumerAdapter {
    fn receive_push_revision(&self, bytes: Bytes) -> FutureResult<(), FlowyError> {
        let user_id = self.user_id.clone();
        let rev_manager = self.rev_manager.clone();
        let edit_cmd_tx = self.editor_edit_queue.clone();
        let shared_sink = self.shared_sink.clone();
        let doc_id = self.doc_id.clone();
        FutureResult::new(async move {
            if let Some(server_composed_revision) =
                handle_push_rev(&doc_id, &user_id, edit_cmd_tx, rev_manager, bytes).await?
            {
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
    revisions: &[Revision],
    edit_cmd: &UnboundedSender<EditorCommand>,
) -> FlowyResult<TransformDeltas> {
    let (ret, rx) = oneshot::channel::<CollaborateResult<TransformDeltas>>();
    // Transform the revision
    let _ = edit_cmd.send(EditorCommand::TransformRevision {
        revisions: revisions.to_vec(),
        ret,
    });
    let transformed_delta = rx.await.map_err(internal_error)??;
    Ok(transformed_delta)
}

async fn compose_pushed_delta(
    delta: RichTextDelta,
    edit_cmd: &UnboundedSender<EditorCommand>,
) -> FlowyResult<DocumentMD5> {
    // compose delta
    let (ret, rx) = oneshot::channel::<CollaborateResult<DocumentMD5>>();
    let _ = edit_cmd.send(EditorCommand::ComposeDelta { delta, ret });
    let md5 = rx.await.map_err(internal_error)??;
    Ok(md5)
}

async fn override_client_delta(
    delta: RichTextDelta,
    edit_cmd: &UnboundedSender<EditorCommand>,
) -> FlowyResult<DocumentMD5> {
    let (ret, rx) = oneshot::channel::<CollaborateResult<DocumentMD5>>();
    let _ = edit_cmd.send(EditorCommand::OverrideDelta { delta, ret });
    let md5 = rx.await.map_err(internal_error)??;
    Ok(md5)
}

async fn make_client_and_server_revision(
    doc_id: &str,
    user_id: &str,
    base_rev_id: i64,
    rev_id: i64,
    client_delta: RichTextDelta,
    server_delta: Option<RichTextDelta>,
    md5: DocumentMD5,
) -> (Revision, Option<Revision>) {
    let client_revision = Revision::new(
        &doc_id,
        base_rev_id,
        rev_id,
        client_delta.to_bytes(),
        &user_id,
        md5.clone(),
    );

    match server_delta {
        None => (client_revision, None),
        Some(server_delta) => {
            let server_revision = Revision::new(&doc_id, base_rev_id, rev_id, server_delta.to_bytes(), &user_id, md5);
            (client_revision, Some(server_revision))
        },
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
    } = transform_pushed_revisions(&revisions, &edit_cmd_tx).await?;
    match server_prime {
        None => {
            // The server_prime is None means the client local revisions conflict with the
            // server, and it needs to override the client delta.
            let md5 = override_client_delta(client_prime.clone(), &edit_cmd_tx).await?;
            let repeated_revision = RepeatedRevision::new(revisions);
            assert_eq!(repeated_revision.last().unwrap().md5, md5);
            let _ = rev_manager.reset_document(repeated_revision).await?;
            Ok(None)
        },
        Some(server_prime) => {
            let md5 = compose_pushed_delta(client_prime.clone(), &edit_cmd_tx).await?;
            for revision in &revisions {
                let _ = rev_manager.add_remote_revision(revision).await?;
            }
            let (base_rev_id, rev_id) = rev_manager.next_rev_id_pair();
            let (client_revision, server_revision) = make_client_and_server_revision(
                doc_id,
                user_id,
                base_rev_id,
                rev_id,
                client_prime,
                Some(server_prime),
                md5,
            )
            .await;

            // save the client revision
            let _ = rev_manager.add_remote_revision(&client_revision).await?;
            Ok(server_revision)
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
