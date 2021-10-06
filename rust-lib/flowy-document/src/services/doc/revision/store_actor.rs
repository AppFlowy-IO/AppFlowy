use crate::{
    entities::doc::{revision_from_doc, Doc, RevId, RevType, Revision, RevisionRange},
    errors::{internal_error, DocError, DocResult},
    services::doc::revision::{model::RevisionOperation, DocRevision, RevisionServer},
    sql_tables::{RevState, RevTableSql},
};
use async_stream::stream;
use dashmap::DashMap;
use flowy_database::ConnectionPool;
use flowy_ot::core::{Attributes, Delta, OperationTransformable};
use futures::{stream::StreamExt, TryFutureExt};
use std::{sync::Arc, time::Duration};
use tokio::{
    sync::{mpsc, oneshot, RwLock},
    task::{spawn_blocking, JoinHandle},
};

pub enum RevisionCmd {
    Revision {
        revision: Revision,
        ret: oneshot::Sender<DocResult<()>>,
    },
    AckRevision {
        rev_id: RevId,
    },
    GetRevisions {
        range: RevisionRange,
        ret: oneshot::Sender<DocResult<Vec<Revision>>>,
    },
    DocumentDelta {
        ret: oneshot::Sender<DocResult<Doc>>,
    },
}

pub struct RevisionStoreActor {
    doc_id: String,
    persistence: Arc<Persistence>,
    revs: Arc<DashMap<i64, RevisionOperation>>,
    delay_save: RwLock<Option<JoinHandle<()>>>,
    receiver: Option<mpsc::Receiver<RevisionCmd>>,
    server: Arc<dyn RevisionServer>,
}

impl RevisionStoreActor {
    pub fn new(
        doc_id: &str,
        pool: Arc<ConnectionPool>,
        receiver: mpsc::Receiver<RevisionCmd>,
        server: Arc<dyn RevisionServer>,
    ) -> RevisionStoreActor {
        let persistence = Arc::new(Persistence::new(pool));
        let revs = Arc::new(DashMap::new());
        let doc_id = doc_id.to_owned();

        Self {
            doc_id,
            persistence,
            revs,
            delay_save: RwLock::new(None),
            receiver: Some(receiver),
            server,
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
        stream.for_each(|msg| self.handle_message(msg)).await;
    }

    async fn handle_message(&self, cmd: RevisionCmd) {
        match cmd {
            RevisionCmd::Revision { revision, ret } => {
                let result = self.handle_new_revision(revision).await;
                let _ = ret.send(result);
            },
            RevisionCmd::AckRevision { rev_id } => {
                self.handle_revision_acked(rev_id).await;
            },
            RevisionCmd::GetRevisions { range, ret } => {
                let result = self.revs_in_range(range).await;
                let _ = ret.send(result);
            },
            RevisionCmd::DocumentDelta { ret } => {
                let delta = self.fetch_document().await;
                let _ = ret.send(delta);
            },
        }
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    async fn handle_new_revision(&self, revision: Revision) -> DocResult<()> {
        if self.revs.contains_key(&revision.rev_id) {
            return Err(DocError::duplicate_rev().context(format!("Duplicate revision id: {}", revision.rev_id)));
        }

        let mut operation = RevisionOperation::new(&revision);
        let _receiver = operation.receiver();
        self.revs.insert(revision.rev_id, operation);
        self.save_revisions().await;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, rev_id))]
    async fn handle_revision_acked(&self, rev_id: RevId) {
        match self.revs.get_mut(rev_id.as_ref()) {
            None => {},
            Some(mut rev) => rev.value_mut().finish(),
        }
        self.save_revisions().await;
    }

    async fn save_revisions(&self) {
        if let Some(handler) = self.delay_save.write().await.take() {
            handler.abort();
        }

        if self.revs.is_empty() {
            return;
        }

        let revs = self.revs.clone();
        let persistence = self.persistence.clone();

        *self.delay_save.write().await = Some(tokio::spawn(async move {
            tokio::time::sleep(Duration::from_millis(300)).await;

            let ids = revs.iter().map(|kv| kv.key().clone()).collect::<Vec<i64>>();
            let revisions = revs
                .iter()
                .map(|kv| ((*kv.value()).clone(), kv.state))
                .collect::<Vec<(Revision, RevState)>>();

            // TODO: Ok to unwrap?
            let conn = &*persistence.pool.get().map_err(internal_error).unwrap();
            let result = conn.immediate_transaction::<_, DocError, _>(|| {
                let _ = persistence.rev_sql.create_rev_table(revisions, conn).unwrap();
                Ok(())
            });

            match result {
                Ok(_) => revs.retain(|k, _| !ids.contains(k)),
                Err(e) => log::error!("Save revision failed: {:?}", e),
            }
        }));
    }

    async fn revs_in_range(&self, range: RevisionRange) -> DocResult<Vec<Revision>> {
        let iter_range = range.from_rev_id..=range.to_rev_id;
        let revs = iter_range
            .flat_map(|rev_id| {
                //
                match self.revs.get(&rev_id) {
                    None => None,
                    Some(rev) => Some((&*(*rev)).clone()),
                }
            })
            .collect::<Vec<Revision>>();

        if revs.len() == range.len() as usize {
            Ok(revs)
        } else {
            let doc_id = self.doc_id.clone();
            let persistence = self.persistence.clone();
            let result = spawn_blocking(move || {
                let conn = &*persistence.pool.get().map_err(internal_error)?;
                let revisions = persistence.rev_sql.read_rev_tables_with_range(&doc_id, range, conn)?;
                Ok(revisions)
            })
            .await
            .map_err(internal_error)?;

            result
        }
    }

    async fn fetch_document(&self) -> DocResult<Doc> {
        let result = fetch_from_local(&self.doc_id, self.persistence.clone()).await;
        if result.is_ok() {
            return result;
        }

        let doc = self.server.fetch_document_from_remote(&self.doc_id).await?;
        let revision = revision_from_doc(doc.clone(), RevType::Remote);
        self.handle_new_revision(revision);
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
