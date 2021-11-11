use crate::{
    entities::doc::{revision_from_doc, Doc, RevId, RevType, Revision, RevisionRange},
    errors::{internal_error, DocError, DocResult},
    services::doc::revision::{model::*, RevisionServer},
    sql_tables::RevState,
};
use async_stream::stream;
use dashmap::DashMap;
use flowy_database::ConnectionPool;
use flowy_infra::future::ResultFuture;
use flowy_ot::core::{Delta, OperationTransformable};
use futures::stream::StreamExt;
use std::{collections::VecDeque, sync::Arc, time::Duration};
use tokio::{
    sync::{broadcast, mpsc, RwLock},
    task::{spawn_blocking, JoinHandle},
};

pub struct RevisionStore {
    doc_id: String,
    persistence: Arc<Persistence>,
    revs_map: Arc<DashMap<i64, RevisionRecord>>,
    pending_tx: PendingSender,
    pending_revs: Arc<RwLock<VecDeque<PendingRevId>>>,
    defer_save_oper: RwLock<Option<JoinHandle<()>>>,
    server: Arc<dyn RevisionServer>,
}

impl RevisionStore {
    pub fn new(
        doc_id: &str,
        pool: Arc<ConnectionPool>,
        server: Arc<dyn RevisionServer>,
        ws_revision_sender: mpsc::UnboundedSender<Revision>,
    ) -> Arc<RevisionStore> {
        let doc_id = doc_id.to_owned();
        let persistence = Arc::new(Persistence::new(pool));
        let revs_map = Arc::new(DashMap::new());
        let (pending_tx, pending_rx) = mpsc::unbounded_channel();
        let pending_revs = Arc::new(RwLock::new(VecDeque::new()));

        let store = Arc::new(Self {
            doc_id,
            persistence,
            revs_map,
            pending_revs,
            pending_tx,
            defer_save_oper: RwLock::new(None),
            server,
        });

        tokio::spawn(RevisionStream::new(store.clone(), pending_rx, ws_revision_sender).run());

        store
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    pub async fn add_revision(&self, revision: Revision) -> DocResult<()> {
        if self.revs_map.contains_key(&revision.rev_id) {
            return Err(DocError::duplicate_rev().context(format!("Duplicate revision id: {}", revision.rev_id)));
        }

        let (sender, receiver) = broadcast::channel(2);
        let revs_map = self.revs_map.clone();
        let mut rx = sender.subscribe();
        tokio::spawn(async move {
            match rx.recv().await {
                Ok(rev_id) => match revs_map.get_mut(&rev_id) {
                    None => {},
                    Some(mut rev) => rev.value_mut().state = RevState::Acked,
                },
                Err(_) => {},
            }
        });

        let pending_rev = PendingRevId::new(revision.rev_id, sender);
        self.pending_revs.write().await.push_back(pending_rev);
        self.revs_map.insert(revision.rev_id, RevisionRecord::new(revision));

        let _ = self.pending_tx.send(PendingMsg::Revision { ret: receiver });
        self.save_revisions().await;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, rev_id), fields(rev_id = %rev_id.as_ref()))]
    pub async fn ack_revision(&self, rev_id: RevId) {
        let rev_id = rev_id.value;
        self.pending_revs
            .write()
            .await
            .retain(|pending| !pending.finish(rev_id));

        self.save_revisions().await;
    }

    async fn save_revisions(&self) {
        if let Some(handler) = self.defer_save_oper.write().await.take() {
            handler.abort();
        }

        if self.revs_map.is_empty() {
            return;
        }

        let revs_map = self.revs_map.clone();
        let persistence = self.persistence.clone();

        *self.defer_save_oper.write().await = Some(tokio::spawn(async move {
            tokio::time::sleep(Duration::from_millis(300)).await;
            let ids = revs_map.iter().map(|kv| kv.key().clone()).collect::<Vec<i64>>();
            let revisions_state = revs_map
                .iter()
                .map(|kv| (kv.revision.clone(), kv.state))
                .collect::<Vec<(Revision, RevState)>>();

            match persistence.create_revs(revisions_state.clone()) {
                Ok(_) => {
                    tracing::debug!(
                        "Revision State Changed: {:?}",
                        revisions_state.iter().map(|s| (s.0.rev_id, s.1)).collect::<Vec<_>>()
                    );
                    revs_map.retain(|k, _| !ids.contains(k));
                },
                Err(e) => log::error!("Save revision failed: {:?}", e),
            }
        }));
    }

    pub async fn revs_in_range(&self, range: RevisionRange) -> DocResult<Vec<Revision>> {
        let revs = range
            .iter()
            .flat_map(|rev_id| match self.revs_map.get(&rev_id) {
                None => None,
                Some(rev) => Some(rev.revision.clone()),
            })
            .collect::<Vec<Revision>>();

        if revs.len() == range.len() as usize {
            Ok(revs)
        } else {
            let doc_id = self.doc_id.clone();
            let persistence = self.persistence.clone();
            let result = spawn_blocking(move || persistence.read_rev_with_range(&doc_id, range))
                .await
                .map_err(internal_error)?;
            result
        }
    }

    pub async fn fetch_document(&self) -> DocResult<Doc> {
        let result = fetch_from_local(&self.doc_id, self.persistence.clone()).await;
        if result.is_ok() {
            return result;
        }

        let doc = self.server.fetch_document_from_remote(&self.doc_id).await?;
        let revision = revision_from_doc(doc.clone(), RevType::Remote);
        let _ = self.persistence.create_revs(vec![(revision, RevState::Acked)])?;
        Ok(doc)
    }
}

impl RevisionIterator for RevisionStore {
    fn next(&self) -> ResultFuture<Option<Revision>, DocError> {
        let pending_revs = self.pending_revs.clone();
        let revs_map = self.revs_map.clone();
        let persistence = self.persistence.clone();
        let doc_id = self.doc_id.clone();
        ResultFuture::new(async move {
            match pending_revs.read().await.front() {
                None => Ok(None),
                Some(pending) => match revs_map.get(&pending.rev_id) {
                    None => persistence.read_rev(&doc_id, &pending.rev_id),
                    Some(context) => Ok(Some(context.revision.clone())),
                },
            }
        })
    }
}

async fn fetch_from_local(doc_id: &str, persistence: Arc<Persistence>) -> DocResult<Doc> {
    let doc_id = doc_id.to_owned();
    spawn_blocking(move || {
        let conn = &*persistence.pool.get().map_err(internal_error)?;
        let revisions = persistence.rev_sql.read_rev_tables(&doc_id, None, conn)?;
        if revisions.is_empty() {
            return Err(DocError::record_not_found().context("Local doesn't have this document"));
        }

        let base_rev_id: RevId = revisions.last().unwrap().base_rev_id.into();
        let rev_id: RevId = revisions.last().unwrap().rev_id.into();
        let mut delta = Delta::new();
        for revision in revisions {
            match Delta::from_bytes(revision.delta_data) {
                Ok(local_delta) => {
                    delta = delta.compose(&local_delta)?;
                },
                Err(e) => {
                    log::error!("Deserialize delta from revision failed: {}", e);
                },
            }
        }
        match delta.ops.last() {
            None => {},
            Some(op) => {
                let data = op.get_data();
                if !data.ends_with("\n") {
                    log::error!("The op must end with newline");
                    log::debug!("Invalid delta: {}", delta.to_json());
                }
            },
        }

        Result::<Doc, DocError>::Ok(Doc {
            id: doc_id,
            data: delta.to_json(),
            rev_id: rev_id.into(),
            base_rev_id: base_rev_id.into(),
        })
    })
    .await
    .map_err(internal_error)?
}

// fn update_revisions(&self) {
//     let rev_ids = self
//         .revs
//         .iter()
//         .flat_map(|kv| match kv.state == RevState::Acked {
//             true => None,
//             false => Some(kv.key().clone()),
//         })
//         .collect::<Vec<i64>>();
//
//     if rev_ids.is_empty() {
//         return;
//     }
//
//     tracing::debug!("Try to update {:?} state", rev_ids);
//     match self.update(&rev_ids) {
//         Ok(_) => {
//             self.revs.retain(|k, _| !rev_ids.contains(k));
//         },
//         Err(e) => log::error!("Save revision failed: {:?}", e),
//     }
// }
//
// fn update(&self, rev_ids: &Vec<i64>) -> Result<(), DocError> {
//     let conn = &*self.pool.get().map_err(internal_error).unwrap();
//     let result = conn.immediate_transaction::<_, DocError, _>(|| {
//         for rev_id in rev_ids {
//             let changeset = RevChangeset {
//                 doc_id: self.doc_id.clone(),
//                 rev_id: rev_id.clone(),
//                 state: RevState::Acked,
//             };
//             let _ = self.op_sql.update_rev_table(changeset, conn)?;
//         }
//         Ok(())
//     });
//
//     result
// }

// fn delete_revision(&self, rev_id: RevId) {
//     let op_sql = self.op_sql.clone();
//     let pool = self.pool.clone();
//     let doc_id = self.doc_id.clone();
//     tokio::spawn(async move {
//         let conn = &*pool.get().map_err(internal_error).unwrap();
//         let result = conn.immediate_transaction::<_, DocError, _>(|| {
//             let _ = op_sql.delete_rev_table(&doc_id, rev_id, conn)?;
//             Ok(())
//         });
//
//         match result {
//             Ok(_) => {},
//             Err(e) => log::error!("Delete revision failed: {:?}", e),
//         }
//     });
// }

pub(crate) enum PendingMsg {
    Revision { ret: RevIdReceiver },
}

pub(crate) type PendingSender = mpsc::UnboundedSender<PendingMsg>;
pub(crate) type PendingReceiver = mpsc::UnboundedReceiver<PendingMsg>;

pub(crate) struct RevisionStream {
    revisions: Arc<dyn RevisionIterator>,
    receiver: Option<PendingReceiver>,
    ws_revision_sender: mpsc::UnboundedSender<Revision>,
}

impl RevisionStream {
    pub(crate) fn new(
        revisions: Arc<dyn RevisionIterator>,
        pending_rx: PendingReceiver,
        ws_revision_sender: mpsc::UnboundedSender<Revision>,
    ) -> Self {
        Self {
            revisions,
            receiver: Some(pending_rx),
            ws_revision_sender,
        }
    }

    pub async fn run(mut self) {
        let mut receiver = self.receiver.take().expect("Should only call once");
        let stream = stream! {
            loop {
                match receiver.recv().await {
                    Some(msg) => yield msg,
                    None => break,
                }
            }
        };
        stream
            .for_each(|msg| async {
                match self.handle_msg(msg).await {
                    Ok(_) => {},
                    Err(e) => log::error!("{:?}", e),
                }
            })
            .await;
    }

    async fn handle_msg(&self, msg: PendingMsg) -> DocResult<()> {
        match msg {
            PendingMsg::Revision { ret } => self.prepare_next_pending_rev(ret).await,
        }
    }

    async fn prepare_next_pending_rev(&self, mut ret: RevIdReceiver) -> DocResult<()> {
        match self.revisions.next().await? {
            None => Ok(()),
            Some(revision) => {
                let _ = self.ws_revision_sender.send(revision).map_err(internal_error);
                let _ = tokio::time::timeout(Duration::from_millis(2000), ret.recv()).await;
                Ok(())
            },
        }
    }
}
