use crate::{errors::FlowyError, module::DocumentUser, services::doc::*};
use bytes::Bytes;
use flowy_collaboration::{
    core::document::history::UndoResult,
    entities::{doc::DocDelta, ws::DocumentWSData},
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
use std::{collections::VecDeque, sync::Arc};
use tokio::sync::{mpsc, mpsc::UnboundedSender, oneshot, RwLock};

pub struct ClientDocEditor {
    pub doc_id: String,
    rev_manager: Arc<RevisionManager>,
    ws_manager: Arc<WebSocketManager>,
    edit_cmd_tx: UnboundedSender<EditCommand>,
    sink_data_provider: SinkDataProvider,
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
        let edit_cmd_tx = spawn_edit_queue(doc_id, delta, pool.clone());
        let doc_id = doc_id.to_string();
        let rev_manager = Arc::new(rev_manager);
        let sink_data_provider = Arc::new(RwLock::new(VecDeque::new()));
        let data_provider = Arc::new(DocumentSinkDataProviderAdapter {
            rev_manager: rev_manager.clone(),
            data_provider: sink_data_provider.clone(),
        });
        let stream_consumer = Arc::new(DocumentWebSocketSteamConsumerAdapter {
            doc_id: doc_id.clone(),
            edit_cmd_tx: edit_cmd_tx.clone(),
            rev_manager: rev_manager.clone(),
            user: user.clone(),
            sink_data_provider: sink_data_provider.clone(),
        });
        let ws_manager = Arc::new(WebSocketManager::new(&doc_id, ws, data_provider, stream_consumer));
        let editor = Arc::new(Self {
            doc_id,
            rev_manager,
            ws_manager,
            edit_cmd_tx,
            sink_data_provider,
            user,
        });
        Ok(editor)
    }

    pub async fn insert<T: ToString>(&self, index: usize, data: T) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<NewDelta>>();
        let msg = EditCommand::Insert {
            index,
            data: data.to_string(),
            ret,
        };
        let _ = self.edit_cmd_tx.send(msg);
        let (delta, md5) = rx.await.map_err(internal_error)??;
        let _ = self.save_local_delta(delta, md5).await?;
        Ok(())
    }

    pub async fn delete(&self, interval: Interval) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<NewDelta>>();
        let msg = EditCommand::Delete { interval, ret };
        let _ = self.edit_cmd_tx.send(msg);
        let (delta, md5) = rx.await.map_err(internal_error)??;
        let _ = self.save_local_delta(delta, md5).await?;
        Ok(())
    }

    pub async fn format(&self, interval: Interval, attribute: RichTextAttribute) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<NewDelta>>();
        let msg = EditCommand::Format {
            interval,
            attribute,
            ret,
        };
        let _ = self.edit_cmd_tx.send(msg);
        let (delta, md5) = rx.await.map_err(internal_error)??;
        let _ = self.save_local_delta(delta, md5).await?;
        Ok(())
    }

    pub async fn replace<T: ToString>(&self, interval: Interval, data: T) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<NewDelta>>();
        let msg = EditCommand::Replace {
            interval,
            data: data.to_string(),
            ret,
        };
        let _ = self.edit_cmd_tx.send(msg);
        let (delta, md5) = rx.await.map_err(internal_error)??;
        let _ = self.save_local_delta(delta, md5).await?;
        Ok(())
    }

    pub async fn can_undo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = EditCommand::CanUndo { ret };
        let _ = self.edit_cmd_tx.send(msg);
        rx.await.unwrap_or(false)
    }

    pub async fn can_redo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = EditCommand::CanRedo { ret };
        let _ = self.edit_cmd_tx.send(msg);
        rx.await.unwrap_or(false)
    }

    pub async fn undo(&self) -> Result<UndoResult, FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<UndoResult>>();
        let msg = EditCommand::Undo { ret };
        let _ = self.edit_cmd_tx.send(msg);
        let r = rx.await.map_err(internal_error)??;
        Ok(r)
    }

    pub async fn redo(&self) -> Result<UndoResult, FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<UndoResult>>();
        let msg = EditCommand::Redo { ret };
        let _ = self.edit_cmd_tx.send(msg);
        let r = rx.await.map_err(internal_error)??;
        Ok(r)
    }

    pub async fn delta(&self) -> FlowyResult<DocDelta> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<DocumentMD5>>();
        let msg = EditCommand::ReadDoc { ret };
        let _ = self.edit_cmd_tx.send(msg);
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
        let msg = EditCommand::ComposeDelta {
            delta: delta.clone(),
            ret,
        };
        let _ = self.edit_cmd_tx.send(msg);
        let md5 = rx.await.map_err(internal_error)??;

        let _ = self.save_local_delta(delta, md5).await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self))]
    pub fn stop_sync(&self) { self.ws_manager.stop(); }

    pub(crate) fn ws_handler(&self) -> Arc<dyn DocumentWsHandler> { self.ws_manager.clone() }
}

fn spawn_edit_queue(doc_id: &str, delta: RichTextDelta, _pool: Arc<ConnectionPool>) -> UnboundedSender<EditCommand> {
    let (sender, receiver) = mpsc::unbounded_channel::<EditCommand>();
    let actor = EditCommandQueue::new(doc_id, delta, receiver);
    tokio::spawn(actor.run());
    sender
}

struct DocumentWebSocketSteamConsumerAdapter {
    doc_id: String,
    edit_cmd_tx: UnboundedSender<EditCommand>,
    rev_manager: Arc<RevisionManager>,
    user: Arc<dyn DocumentUser>,
    sink_data_provider: SinkDataProvider,
}

impl DocumentWebSocketSteamConsumer for DocumentWebSocketSteamConsumerAdapter {
    fn receive_push_revision(&self, bytes: Bytes) -> FutureResult<(), FlowyError> {
        let user = self.user.clone();
        let rev_manager = self.rev_manager.clone();
        let edit_cmd_tx = self.edit_cmd_tx.clone();
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
                        tracing::debug!("[DocumentSinkDataProvider]: revision: {}:{:?}", rev.doc_id, rev.rev_id);
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
    edit_cmd_tx: UnboundedSender<EditCommand>,
    rev_manager: Arc<RevisionManager>,
    bytes: Bytes,
) -> FlowyResult<Option<Revision>> {
    // Transform the revision
    let (ret, rx) = oneshot::channel::<CollaborateResult<TransformDeltas>>();
    let _ = edit_cmd_tx.send(EditCommand::ProcessRemoteRevision { bytes, ret });
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
    let msg = EditCommand::ComposeDelta {
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
        let msg = EditCommand::ReadDoc { ret };
        let _ = self.edit_cmd_tx.send(msg);
        let s = rx.await.map_err(internal_error)??;
        Ok(s)
    }

    pub async fn doc_delta(&self) -> FlowyResult<RichTextDelta> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<RichTextDelta>>();
        let msg = EditCommand::ReadDocDelta { ret };
        let _ = self.edit_cmd_tx.send(msg);
        let delta = rx.await.map_err(internal_error)??;
        Ok(delta)
    }

    pub fn rev_manager(&self) -> Arc<RevisionManager> { self.rev_manager.clone() }
}
