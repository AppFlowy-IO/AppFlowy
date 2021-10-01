use crate::{
    entities::doc::{Revision, RevisionRange},
    errors::{internal_error, DocError, DocResult},
    services::doc::rev_manager::util::RevisionOperation,
    sql_tables::{OpTableSql, RevChangeset, RevState},
};
use async_stream::stream;
use dashmap::DashMap;
use flowy_database::ConnectionPool;
use futures::stream::StreamExt;

use std::{cell::RefCell, sync::Arc, time::Duration};
use tokio::{
    sync::{mpsc, oneshot, RwLock},
    task::JoinHandle,
};

pub enum StoreMsg {
    Revision {
        revision: Revision,
    },
    AckRevision {
        rev_id: i64,
    },
    SendRevisions {
        range: RevisionRange,
        ret: oneshot::Sender<DocResult<Vec<Revision>>>,
    },
}

pub struct Store {
    doc_id: String,
    op_sql: Arc<OpTableSql>,
    pool: Arc<ConnectionPool>,
    revs: Arc<DashMap<i64, RevisionOperation>>,
    delay_save: RwLock<Option<JoinHandle<()>>>,
    receiver: Option<mpsc::Receiver<StoreMsg>>,
}

impl Store {
    pub fn new(doc_id: &str, pool: Arc<ConnectionPool>, receiver: mpsc::Receiver<StoreMsg>) -> Store {
        let op_sql = Arc::new(OpTableSql {});
        let revs = Arc::new(DashMap::new());
        let doc_id = doc_id.to_owned();

        Self {
            doc_id,
            op_sql,
            pool,
            revs,
            delay_save: RwLock::new(None),
            receiver: Some(receiver),
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

    async fn handle_message(&self, msg: StoreMsg) {
        match msg {
            StoreMsg::Revision { revision } => {
                self.handle_new_revision(revision).await;
            },
            StoreMsg::AckRevision { rev_id } => {
                self.handle_revision_acked(rev_id).await;
            },
            StoreMsg::SendRevisions { range: _, ret: _ } => {
                unimplemented!()
            },
        }
    }

    async fn handle_new_revision(&self, revision: Revision) {
        let mut operation = RevisionOperation::new(&revision);
        let _receiver = operation.receiver();
        self.revs.insert(revision.rev_id, operation);
        self.save_revisions().await;
    }

    async fn handle_revision_acked(&self, rev_id: i64) {
        match self.revs.get_mut(&rev_id) {
            None => {},
            Some(mut rev) => rev.value_mut().finish(),
        }
        self.save_revisions().await;
    }

    pub fn revs_in_range(&self, _range: RevisionRange) -> DocResult<Vec<Revision>> { unimplemented!() }

    async fn save_revisions(&self) {
        if let Some(handler) = self.delay_save.write().await.take() {
            handler.abort();
        }

        if self.revs.is_empty() {
            return;
        }

        let revs = self.revs.clone();
        let pool = self.pool.clone();
        let op_sql = self.op_sql.clone();

        *self.delay_save.write().await = Some(tokio::spawn(async move {
            tokio::time::sleep(Duration::from_millis(300)).await;

            let ids = revs.iter().map(|kv| kv.key().clone()).collect::<Vec<i64>>();
            let revisions = revs
                .iter()
                .map(|kv| ((*kv.value()).clone(), kv.state))
                .collect::<Vec<(Revision, RevState)>>();

            let conn = &*pool.get().map_err(internal_error).unwrap();
            let result = conn.immediate_transaction::<_, DocError, _>(|| {
                let _ = op_sql.create_rev_table(revisions, conn).unwrap();
                Ok(())
            });

            match result {
                Ok(_) => revs.retain(|k, _| !ids.contains(k)),
                Err(e) => log::error!("Save revision failed: {:?}", e),
            }
        }));
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

    // fn delete_revision(&self, rev_id: i64) {
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
}
