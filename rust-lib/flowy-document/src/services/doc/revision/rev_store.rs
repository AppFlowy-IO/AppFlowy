use crate::{
    entities::doc::{revision_from_doc, Doc, RevId, RevType, Revision, RevisionRange},
    errors::{internal_error, DocError, DocResult},
    services::doc::revision::{
        model::{PendingRevId, PendingRevReceiver, RevisionContext},
        RevisionServer,
    },
    sql_tables::{RevState, RevTableSql},
};
use async_stream::stream;
use dashmap::{mapref::one::Ref, DashMap, DashSet};
use flowy_database::ConnectionPool;
use flowy_ot::core::{Delta, OperationTransformable};
use futures::{stream::StreamExt, TryFutureExt};
use std::{
    collections::{HashMap, VecDeque},
    sync::Arc,
    time::Duration,
};
use tokio::{
    sync::{mpsc, oneshot, RwLock, RwLockWriteGuard},
    task::{spawn_blocking, JoinHandle},
};

pub struct RevisionStoreActor {
    doc_id: String,
    persistence: Arc<Persistence>,
    revs_map: Arc<DashMap<i64, RevisionContext>>,
    pending_revs_sender: RevSender,
    pending_revs: Arc<RwLock<VecDeque<PendingRevId>>>,
    delay_save: RwLock<Option<JoinHandle<()>>>,
    server: Arc<dyn RevisionServer>,
}

impl RevisionStoreActor {
    pub fn new(
        doc_id: &str,
        pool: Arc<ConnectionPool>,
        server: Arc<dyn RevisionServer>,
        pending_rev_sender: mpsc::Sender<Revision>,
    ) -> RevisionStoreActor {
        let doc_id = doc_id.to_owned();
        let persistence = Arc::new(Persistence::new(pool));
        let revs_map = Arc::new(DashMap::new());
        let (pending_revs_sender, receiver) = mpsc::unbounded_channel();
        let pending_revs = Arc::new(RwLock::new(VecDeque::new()));
        let pending = PendingRevision::new(
            &doc_id,
            receiver,
            persistence.clone(),
            revs_map.clone(),
            pending_rev_sender,
            pending_revs.clone(),
        );
        tokio::spawn(pending.run());

        Self {
            doc_id,
            persistence,
            revs_map,
            pending_revs_sender,
            pending_revs,
            delay_save: RwLock::new(None),
            server,
        }
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    pub async fn handle_new_revision(&self, revision: Revision) -> DocResult<()> {
        if self.revs_map.contains_key(&revision.rev_id) {
            return Err(DocError::duplicate_rev().context(format!("Duplicate revision id: {}", revision.rev_id)));
        }

        self.pending_revs_sender.send(PendingRevisionMsg::Revision {
            revision: revision.clone(),
        });
        self.revs_map.insert(revision.rev_id, RevisionContext::new(revision));
        self.save_revisions().await;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, rev_id))]
    pub async fn handle_revision_acked(&self, rev_id: RevId) {
        let rev_id = rev_id.value;
        log::debug!("Receive revision acked: {}", rev_id);
        match self.pending_revs.write().await.pop_front() {
            None => {},
            Some(pending) => {
                debug_assert!(pending.rev_id == rev_id);
                if pending.rev_id != rev_id {
                    log::error!(
                        "Acked: expected rev_id: {:?}, but receive: {:?}",
                        pending.rev_id,
                        rev_id
                    );
                }
                pending.sender.send(Ok(()));
            },
        }
        match self.revs_map.get_mut(&rev_id) {
            None => {},
            Some(mut rev) => rev.value_mut().state = RevState::Acked,
        }
        self.save_revisions().await;
    }

    async fn save_revisions(&self) {
        if let Some(handler) = self.delay_save.write().await.take() {
            handler.abort();
        }

        if self.revs_map.is_empty() {
            return;
        }

        let revs_map = self.revs_map.clone();
        let persistence = self.persistence.clone();

        *self.delay_save.write().await = Some(tokio::spawn(async move {
            tokio::time::sleep(Duration::from_millis(300)).await;
            let ids = revs_map.iter().map(|kv| kv.key().clone()).collect::<Vec<i64>>();
            let revisions_state = revs_map
                .iter()
                .map(|kv| (kv.revision.clone(), kv.state))
                .collect::<Vec<(Revision, RevState)>>();

            // TODO: Ok to unwrap?
            let conn = &*persistence.pool.get().map_err(internal_error).unwrap();
            let result = conn.immediate_transaction::<_, DocError, _>(|| {
                let _ = persistence.rev_sql.create_rev_table(revisions_state, conn).unwrap();
                Ok(())
            });

            match result {
                Ok(_) => revs_map.retain(|k, _| !ids.contains(k)),
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
            let result = spawn_blocking(move || {
                let conn = &*persistence.pool.get().map_err(internal_error).unwrap();
                let revisions = persistence.rev_sql.read_rev_tables_with_range(&doc_id, range, conn)?;
                Ok(revisions)
            })
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
        let conn = &*self.persistence.pool.get().map_err(internal_error).unwrap();
        let _ = conn.immediate_transaction::<_, DocError, _>(|| {
            let _ = self
                .persistence
                .rev_sql
                .create_rev_table(vec![(revision, RevState::Acked)], conn)
                .unwrap();
            Ok(())
        })?;

        Ok(doc)
    }
}

async fn fetch_from_local(doc_id: &str, persistence: Arc<Persistence>) -> DocResult<Doc> {
    let doc_id = doc_id.to_owned();
    spawn_blocking(move || {
        let conn = &*persistence.pool.get().map_err(internal_error)?;
        let revisions = persistence.rev_sql.read_rev_tables(&doc_id, None, conn)?;
        if revisions.is_empty() {
            return Err(DocError::not_found());
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

struct Persistence {
    rev_sql: Arc<RevTableSql>,
    pool: Arc<ConnectionPool>,
}

impl Persistence {
    fn new(pool: Arc<ConnectionPool>) -> Self {
        let rev_sql = Arc::new(RevTableSql {});
        Self { rev_sql, pool }
    }
}

enum PendingRevisionMsg {
    Revision { revision: Revision },
}

type RevSender = mpsc::UnboundedSender<PendingRevisionMsg>;
type RevReceiver = mpsc::UnboundedReceiver<PendingRevisionMsg>;

struct PendingRevision {
    doc_id: String,
    pending_revs: Arc<RwLock<VecDeque<PendingRevId>>>,
    persistence: Arc<Persistence>,
    revs_map: Arc<DashMap<i64, RevisionContext>>,
    msg_receiver: Option<RevReceiver>,
    next_rev: mpsc::Sender<Revision>,
}

impl PendingRevision {
    pub fn new(
        doc_id: &str,
        msg_receiver: RevReceiver,
        persistence: Arc<Persistence>,
        revs_map: Arc<DashMap<i64, RevisionContext>>,
        next_rev: mpsc::Sender<Revision>,
        pending_revs: Arc<RwLock<VecDeque<PendingRevId>>>,
    ) -> Self {
        Self {
            doc_id: doc_id.to_owned(),
            pending_revs,
            msg_receiver: Some(msg_receiver),
            persistence,
            revs_map,
            next_rev,
        }
    }

    pub async fn run(mut self) {
        let mut receiver = self.msg_receiver.take().expect("Should only call once");
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

    async fn handle_msg(&self, msg: PendingRevisionMsg) -> DocResult<()> {
        match msg {
            PendingRevisionMsg::Revision { revision } => self.handle_revision(revision).await,
        }
    }

    async fn handle_revision(&self, revision: Revision) -> DocResult<()> {
        let (sender, receiver) = oneshot::channel();
        let pending_rev = PendingRevId {
            rev_id: revision.rev_id,
            sender,
        };
        self.pending_revs.write().await.push_back(pending_rev);
        let _ = self.prepare_next_pending_rev(receiver).await?;
        Ok(())
    }

    async fn prepare_next_pending_rev(&self, done: PendingRevReceiver) -> DocResult<()> {
        let next_rev_notify = self.next_rev.clone();
        let doc_id = self.doc_id.clone();
        let _ = match self.pending_revs.read().await.front() {
            None => Ok(()),
            Some(pending) => match self.revs_map.get(&pending.rev_id) {
                None => {
                    let conn = self.persistence.pool.get().map_err(internal_error)?;
                    let some = self
                        .persistence
                        .rev_sql
                        .read_rev_table(&doc_id, &pending.rev_id, &*conn)?;
                    match some {
                        Some(revision) => next_rev_notify.send(revision).await.map_err(internal_error),
                        None => Ok(()),
                    }
                },
                Some(context) => next_rev_notify
                    .send(context.revision.clone())
                    .await
                    .map_err(internal_error),
            },
        }?;
        let _ = tokio::time::timeout(Duration::from_millis(2000), done).await;
        Ok(())
    }
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
//     log::debug!("Try to update {:?} state", rev_ids);
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
