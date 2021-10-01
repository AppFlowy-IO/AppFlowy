use crate::{
    entities::{
        doc::{Doc, RevType, Revision, RevisionRange},
        ws::{WsDataType, WsDocumentData},
    },
    errors::{internal_error, DocError, DocResult},
    services::{
        doc::{
            edit::cache::{DocumentEditActor, EditMsg},
            rev_manager::RevisionManager,
            UndoResult,
        },
        util::bytes_to_rev_id,
        ws::{WsDocumentHandler, WsDocumentSender},
    },
};
use bytes::Bytes;
use flowy_database::ConnectionPool;
use flowy_ot::core::{Attribute, Delta, Interval};
use std::{convert::TryFrom, sync::Arc};
use tokio::sync::{mpsc, mpsc::UnboundedSender, oneshot};

pub type DocId = String;

pub struct EditDocContext {
    pub doc_id: DocId,
    rev_manager: Arc<RevisionManager>,
    document: UnboundedSender<EditMsg>,
    pool: Arc<ConnectionPool>,
}

impl EditDocContext {
    pub(crate) async fn new(
        doc: Doc,
        pool: Arc<ConnectionPool>,
        ws_sender: Arc<dyn WsDocumentSender>,
    ) -> Result<Self, DocError> {
        let delta = Delta::from_bytes(doc.data)?;
        let (sender, receiver) = mpsc::unbounded_channel::<EditMsg>();
        let edit_actor = DocumentEditActor::new(&doc.id, delta, pool.clone(), receiver);
        tokio::task::spawn_local(edit_actor.run());

        let rev_manager = Arc::new(RevisionManager::new(&doc.id, doc.rev_id, pool.clone(), ws_sender));
        let edit_context = Self {
            doc_id: doc.id,
            rev_manager,
            document: sender,
            pool,
        };
        Ok(edit_context)
    }

    pub async fn insert<T: ToString>(&self, index: usize, data: T) -> Result<(), DocError> {
        let (ret, rx) = oneshot::channel::<DocResult<Delta>>();
        let msg = EditMsg::Insert {
            index,
            data: data.to_string(),
            ret,
        };
        let _ = self.document.send(msg);
        let delta_data = rx.await.map_err(internal_error)??.to_bytes();
        let rev_id = self.mk_revision(&delta_data).await?;
        save(rev_id, self.document.clone()).await
    }

    pub async fn delete(&self, interval: Interval) -> Result<(), DocError> {
        let (ret, rx) = oneshot::channel::<DocResult<Delta>>();
        let msg = EditMsg::Delete { interval, ret };
        let _ = self.document.send(msg);
        let delta_data = rx.await.map_err(internal_error)??.to_bytes();
        let _ = self.mk_revision(&delta_data).await?;
        Ok(())
    }

    pub async fn format(&self, interval: Interval, attribute: Attribute) -> Result<(), DocError> {
        let (ret, rx) = oneshot::channel::<DocResult<Delta>>();
        let msg = EditMsg::Format {
            interval,
            attribute,
            ret,
        };
        let _ = self.document.send(msg);
        let delta_data = rx.await.map_err(internal_error)??.to_bytes();
        let _ = self.mk_revision(&delta_data).await?;
        Ok(())
    }

    pub async fn replace<T: ToString>(&mut self, interval: Interval, data: T) -> Result<(), DocError> {
        let (ret, rx) = oneshot::channel::<DocResult<Delta>>();
        let msg = EditMsg::Replace {
            interval,
            data: data.to_string(),
            ret,
        };
        let _ = self.document.send(msg);
        let delta_data = rx.await.map_err(internal_error)??.to_bytes();
        let _ = self.mk_revision(&delta_data).await?;
        Ok(())
    }

    pub async fn can_undo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = EditMsg::CanUndo { ret };
        let _ = self.document.send(msg);
        rx.await.unwrap_or(false)
    }

    pub async fn can_redo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = EditMsg::CanRedo { ret };
        let _ = self.document.send(msg);
        rx.await.unwrap_or(false)
    }

    pub async fn undo(&self) -> Result<UndoResult, DocError> {
        let (ret, rx) = oneshot::channel::<DocResult<UndoResult>>();
        let msg = EditMsg::Undo { ret };
        let _ = self.document.send(msg);
        rx.await.map_err(internal_error)?
    }

    pub async fn redo(&self) -> Result<UndoResult, DocError> {
        let (ret, rx) = oneshot::channel::<DocResult<UndoResult>>();
        let msg = EditMsg::Redo { ret };
        let _ = self.document.send(msg);
        rx.await.map_err(internal_error)?
    }

    pub async fn doc(&self) -> DocResult<Doc> {
        let (ret, rx) = oneshot::channel::<DocResult<String>>();
        let msg = EditMsg::Doc { ret };
        let _ = self.document.send(msg);
        let data = rx.await.map_err(internal_error)??;
        let rev_id = self.rev_manager.rev_id();
        let id = self.doc_id.clone();

        Ok(Doc { id, data, rev_id })
    }

    async fn mk_revision(&self, delta_data: &Bytes) -> Result<i64, DocError> {
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id();
        let delta_data = delta_data.to_vec();
        let revision = Revision::new(base_rev_id, rev_id, delta_data, &self.doc_id, RevType::Local);
        self.rev_manager.add_revision(revision).await;
        Ok(rev_id)
    }

    #[tracing::instrument(level = "debug", skip(self, data), err)]
    pub(crate) async fn compose_local_delta(&self, data: Bytes) -> Result<(), DocError> {
        let delta = Delta::from_bytes(&data)?;
        let (ret, rx) = oneshot::channel::<DocResult<()>>();
        let msg = EditMsg::Delta { delta, ret };
        let _ = self.document.send(msg);
        let _ = rx.await.map_err(internal_error)??;

        let rev_id = self.mk_revision(&data).await?;
        save(rev_id, self.document.clone()).await
    }

    #[cfg(feature = "flowy_test")]
    pub async fn doc_json(&self) -> DocResult<String> {
        let (ret, rx) = oneshot::channel::<DocResult<String>>();
        let msg = EditMsg::Doc { ret };
        let _ = self.document.send(msg);
        rx.await.map_err(internal_error)?
    }
}

impl WsDocumentHandler for EditDocContext {
    fn receive(&self, doc_data: WsDocumentData) {
        let document = self.document.clone();
        let rev_manager = self.rev_manager.clone();
        let f = |doc_data: WsDocumentData| async move {
            let bytes = Bytes::from(doc_data.data);
            match doc_data.ty {
                WsDataType::PushRev => {
                    let _ = handle_push_rev(bytes, rev_manager, document).await?;
                },
                WsDataType::PullRev => {
                    let range = RevisionRange::try_from(bytes)?;
                    let _ = rev_manager.send_revisions(range)?;
                },
                WsDataType::Acked => {
                    let rev_id = bytes_to_rev_id(bytes.to_vec())?;
                    let _ = rev_manager.ack_rev(rev_id);
                },
                WsDataType::Conflict => {},
            }
            Result::<(), DocError>::Ok(())
        };

        tokio::spawn(async move {
            if let Err(e) = f(doc_data).await {
                log::error!("{:?}", e);
            }
        });
    }
}

async fn save(rev_id: i64, document: UnboundedSender<EditMsg>) -> DocResult<()> {
    let (ret, rx) = oneshot::channel::<DocResult<()>>();
    let _ = document.send(EditMsg::SaveRevision { rev_id, ret });
    let result = rx.await.map_err(internal_error)?;
    result
}

async fn handle_push_rev(
    rev_bytes: Bytes,
    rev_manager: Arc<RevisionManager>,
    document: UnboundedSender<EditMsg>,
) -> DocResult<()> {
    let revision = Revision::try_from(rev_bytes)?;
    let _ = rev_manager.add_revision(revision).await?;
    match rev_manager.next_compose_revision() {
        None => Ok(()),
        Some(revision) => {
            let delta = Delta::from_bytes(&revision.delta_data)?;
            let (ret, rx) = oneshot::channel::<DocResult<()>>();
            let msg = EditMsg::Delta { delta, ret };
            let _ = document.send(msg);

            match rx.await.map_err(internal_error)? {
                Ok(_) => save(revision.rev_id, document).await,
                Err(e) => {
                    rev_manager.push_compose_revision(revision);
                    Err(e)
                },
            }
        },
    }
}
