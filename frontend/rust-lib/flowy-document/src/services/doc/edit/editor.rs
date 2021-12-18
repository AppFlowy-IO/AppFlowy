use crate::{errors::FlowyError, module::DocumentUser, services::doc::*};
use bytes::Bytes;
use flowy_collaboration::{
    core::document::history::UndoResult,
    entities::{
        doc::DocDelta,
        ws::{DocumentConnected, DocumentWSData, DocumentWSDataType, WsDocumentDataBuilder},
    },
    errors::CollaborateResult,
};
use flowy_database::ConnectionPool;
use flowy_error::{internal_error, FlowyResult};
use lib_infra::future::FutureResult;
use lib_ot::{
    core::Interval,
    revision::{RevId, RevType, Revision, RevisionRange},
    rich_text::{RichTextAttribute, RichTextDelta},
};
use lib_ws::WSConnectState;
use std::{collections::VecDeque, sync::Arc};
use tokio::sync::{broadcast, mpsc, mpsc::UnboundedSender, oneshot, RwLock};

pub struct ClientDocEditor {
    pub doc_id: String,
    rev_manager: Arc<RevisionManager>,
    editor_ws: Arc<EditorWebSocket>,
    editor_cmd_sender: UnboundedSender<EditorCommand>,
    user: Arc<dyn DocumentUser>,
}

impl ClientDocEditor {
    pub(crate) async fn new(
        doc_id: &str,
        user: Arc<dyn DocumentUser>,
        pool: Arc<ConnectionPool>,
        mut rev_manager: RevisionManager,
        ws: Arc<dyn DocumentWebSocket>,
        server: Arc<dyn RevisionServer>,
    ) -> FlowyResult<Arc<Self>> {
        let delta = rev_manager.load_document(server).await?;
        let editor_cmd_sender = spawn_edit_queue(doc_id, delta, pool.clone());
        let doc_id = doc_id.to_string();
        let user_id = user.user_id()?;
        let rev_manager = Arc::new(rev_manager);
        let sink_data_provider = Arc::new(RwLock::new(VecDeque::new()));
        let data_provider = Arc::new(DocumentSinkDataProviderAdapter {
            rev_manager: rev_manager.clone(),
            data_provider: sink_data_provider.clone(),
        });
        let stream_consumer = Arc::new(DocumentWebSocketSteamConsumerAdapter {
            doc_id: doc_id.clone(),
            editor_cmd_sender: editor_cmd_sender.clone(),
            rev_manager: rev_manager.clone(),
            user: user.clone(),
            sink_data_provider: sink_data_provider.clone(),
        });
        let editor_ws = Arc::new(EditorWebSocket::new(&doc_id, ws, data_provider, stream_consumer));
        notify_user_conn(&user_id, &doc_id, rev_manager.clone(), sink_data_provider.clone()).await;

        listen_document_ws_state(
            &user_id,
            &doc_id,
            editor_ws.scribe_state(),
            rev_manager.clone(),
            sink_data_provider,
        );

        let editor = Arc::new(Self {
            doc_id,
            rev_manager,
            editor_ws,
            editor_cmd_sender,
            user,
        });
        Ok(editor)
    }

    pub async fn insert<T: ToString>(&self, index: usize, data: T) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<NewDelta>>();
        let msg = EditorCommand::Insert {
            index,
            data: data.to_string(),
            ret,
        };
        let _ = self.editor_cmd_sender.send(msg);
        let (delta, md5) = rx.await.map_err(internal_error)??;
        let _ = self.save_local_delta(delta, md5).await?;
        Ok(())
    }

    pub async fn delete(&self, interval: Interval) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<NewDelta>>();
        let msg = EditorCommand::Delete { interval, ret };
        let _ = self.editor_cmd_sender.send(msg);
        let (delta, md5) = rx.await.map_err(internal_error)??;
        let _ = self.save_local_delta(delta, md5).await?;
        Ok(())
    }

    pub async fn format(&self, interval: Interval, attribute: RichTextAttribute) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<NewDelta>>();
        let msg = EditorCommand::Format {
            interval,
            attribute,
            ret,
        };
        let _ = self.editor_cmd_sender.send(msg);
        let (delta, md5) = rx.await.map_err(internal_error)??;
        let _ = self.save_local_delta(delta, md5).await?;
        Ok(())
    }

    pub async fn replace<T: ToString>(&self, interval: Interval, data: T) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<NewDelta>>();
        let msg = EditorCommand::Replace {
            interval,
            data: data.to_string(),
            ret,
        };
        let _ = self.editor_cmd_sender.send(msg);
        let (delta, md5) = rx.await.map_err(internal_error)??;
        let _ = self.save_local_delta(delta, md5).await?;
        Ok(())
    }

    pub async fn can_undo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = EditorCommand::CanUndo { ret };
        let _ = self.editor_cmd_sender.send(msg);
        rx.await.unwrap_or(false)
    }

    pub async fn can_redo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = EditorCommand::CanRedo { ret };
        let _ = self.editor_cmd_sender.send(msg);
        rx.await.unwrap_or(false)
    }

    pub async fn undo(&self) -> Result<UndoResult, FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<UndoResult>>();
        let msg = EditorCommand::Undo { ret };
        let _ = self.editor_cmd_sender.send(msg);
        let r = rx.await.map_err(internal_error)??;
        Ok(r)
    }

    pub async fn redo(&self) -> Result<UndoResult, FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<UndoResult>>();
        let msg = EditorCommand::Redo { ret };
        let _ = self.editor_cmd_sender.send(msg);
        let r = rx.await.map_err(internal_error)??;
        Ok(r)
    }

    pub async fn delta(&self) -> FlowyResult<DocDelta> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<DocumentMD5>>();
        let msg = EditorCommand::ReadDoc { ret };
        let _ = self.editor_cmd_sender.send(msg);
        let data = rx.await.map_err(internal_error)??;

        Ok(DocDelta {
            doc_id: self.doc_id.clone(),
            data,
        })
    }

    async fn save_local_delta(&self, delta: RichTextDelta, md5: String) -> Result<RevId, FlowyError> {
        let delta_data = delta.to_bytes();
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id();
        let user_id = self.user.user_id()?;
        let revision = Revision::new(
            &self.doc_id,
            base_rev_id,
            rev_id,
            delta_data,
            RevType::Local,
            &user_id,
            md5,
        );
        let _ = self.rev_manager.add_local_revision(&revision).await?;
        Ok(rev_id.into())
    }

    #[tracing::instrument(level = "debug", skip(self, data), err)]
    pub(crate) async fn composing_local_delta(&self, data: Bytes) -> Result<(), FlowyError> {
        let delta = RichTextDelta::from_bytes(&data)?;
        let (ret, rx) = oneshot::channel::<CollaborateResult<DocumentMD5>>();
        let msg = EditorCommand::ComposeDelta {
            delta: delta.clone(),
            ret,
        };
        let _ = self.editor_cmd_sender.send(msg);
        let md5 = rx.await.map_err(internal_error)??;

        let _ = self.save_local_delta(delta, md5).await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self))]
    pub fn stop_sync(&self) { self.editor_ws.stop(); }

    pub(crate) fn ws_handler(&self) -> Arc<dyn DocumentWsHandler> { self.editor_ws.clone() }
}

fn spawn_edit_queue(doc_id: &str, delta: RichTextDelta, _pool: Arc<ConnectionPool>) -> UnboundedSender<EditorCommand> {
    let (sender, receiver) = mpsc::unbounded_channel::<EditorCommand>();
    let actor = EditorCommandQueue::new(doc_id, delta, receiver);
    tokio::spawn(actor.run());
    sender
}

struct DocumentWebSocketSteamConsumerAdapter {
    doc_id: String,
    editor_cmd_sender: UnboundedSender<EditorCommand>,
    rev_manager: Arc<RevisionManager>,
    user: Arc<dyn DocumentUser>,
    sink_data_provider: SinkDataProvider,
}

impl DocumentWebSocketSteamConsumer for DocumentWebSocketSteamConsumerAdapter {
    fn receive_push_revision(&self, bytes: Bytes) -> FutureResult<(), FlowyError> {
        let user = self.user.clone();
        let rev_manager = self.rev_manager.clone();
        let edit_cmd_tx = self.editor_cmd_sender.clone();
        let sink_data_provider = self.sink_data_provider.clone();
        let doc_id = self.doc_id.clone();
        FutureResult::new(async move {
            let user_id = user.user_id()?;
            if let Some(revision) = handle_push_rev(&doc_id, &user_id, edit_cmd_tx, rev_manager, bytes).await? {
                sink_data_provider.write().await.push_back(revision.into());
            }
            Ok(())
        })
    }

    fn receive_ack_revision(&self, rev_id: i64) -> FutureResult<(), FlowyError> {
        let rev_manager = self.rev_manager.clone();
        FutureResult::new(async move {
            let _ = rev_manager.ack_revision(rev_id).await?;
            Ok(())
        })
    }

    fn send_revision_in_range(&self, range: RevisionRange) -> FutureResult<(), FlowyError> {
        let rev_manager = self.rev_manager.clone();
        let sink_data_provider = self.sink_data_provider.clone();
        FutureResult::new(async move {
            let revision = rev_manager.mk_revisions(range).await?;
            sink_data_provider.write().await.push_back(revision.into());
            Ok(())
        })
    }
}

async fn notify_user_conn(
    user_id: &str,
    doc_id: &str,
    rev_manager: Arc<RevisionManager>,
    sink_data_provider: SinkDataProvider,
) {
    let need_notify = match sink_data_provider.read().await.front() {
        None => true,
        Some(data) => data.ty != DocumentWSDataType::UserConnect,
    };

    if need_notify {
        let document_conn = DocumentConnected {
            user_id: user_id.to_owned(),
            doc_id: doc_id.to_owned(),
            rev_id: rev_manager.latest_rev_id(),
        };

        let data = WsDocumentDataBuilder::build_document_conn_message(doc_id, document_conn);
        sink_data_provider.write().await.push_front(data);
    }
}

fn listen_document_ws_state(
    user_id: &str,
    doc_id: &str,
    mut subscriber: broadcast::Receiver<WSConnectState>,
    rev_manager: Arc<RevisionManager>,
    sink_data_provider: SinkDataProvider,
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

type SinkDataProvider = Arc<RwLock<VecDeque<DocumentWSData>>>;

struct DocumentSinkDataProviderAdapter {
    rev_manager: Arc<RevisionManager>,
    data_provider: SinkDataProvider,
}

impl DocumentSinkDataProvider for DocumentSinkDataProviderAdapter {
    fn next(&self) -> FutureResult<Option<DocumentWSData>, FlowyError> {
        let rev_manager = self.rev_manager.clone();
        let data_provider = self.data_provider.clone();

        FutureResult::new(async move {
            if data_provider.read().await.is_empty() {
                match rev_manager.next_sync_revision().await? {
                    Some(rev) => {
                        tracing::debug!("[DocumentSinkDataProvider]: {}:{:?}", rev.doc_id, rev.rev_id);
                        Ok(Some(rev.into()))
                    },
                    None => Ok(None),
                }
            } else {
                match data_provider.read().await.front() {
                    None => Ok(None),
                    Some(data) => {
                        tracing::debug!("[DocumentSinkDataProvider]: {}:{:?}", data.doc_id, data.ty);
                        Ok(Some(data.clone()))
                    },
                }
            }
        })
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

#[cfg(feature = "flowy_unit_test")]
impl ClientDocEditor {
    pub async fn doc_json(&self) -> FlowyResult<String> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<DocumentMD5>>();
        let msg = EditorCommand::ReadDoc { ret };
        let _ = self.editor_cmd_sender.send(msg);
        let s = rx.await.map_err(internal_error)??;
        Ok(s)
    }

    pub async fn doc_delta(&self) -> FlowyResult<RichTextDelta> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<RichTextDelta>>();
        let msg = EditorCommand::ReadDocDelta { ret };
        let _ = self.editor_cmd_sender.send(msg);
        let delta = rx.await.map_err(internal_error)??;
        Ok(delta)
    }

    pub fn rev_manager(&self) -> Arc<RevisionManager> { self.rev_manager.clone() }
}
