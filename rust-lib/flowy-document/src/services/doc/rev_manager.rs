use crate::{
    entities::doc::{RevType, Revision, RevisionRange},
    errors::{internal_error, DocError},
    services::{util::RevIdCounter, ws::WsDocumentSender},
    sql_tables::{OpTableSql, RevChangeset, RevState},
};
use dashmap::DashSet;
use flowy_database::ConnectionPool;
use parking_lot::RwLock;
use std::{
    collections::{HashMap, VecDeque},
    sync::Arc,
};
use tokio::{task::JoinHandle, time::Duration};

pub struct RevisionManager {
    doc_id: String,
    op_sql: Arc<OpTableSql>,
    pool: Arc<ConnectionPool>,
    rev_id_counter: RevIdCounter,
    ws_sender: Arc<dyn WsDocumentSender>,
    rev_cache: Arc<RwLock<HashMap<i64, Revision>>>,
    ack_rev_cache: Arc<DashSet<i64>>,
    remote_rev_cache: RwLock<VecDeque<Revision>>,
    save_operation: RwLock<Option<JoinHandle<()>>>,
}

impl RevisionManager {
    pub fn new(doc_id: &str, rev_id: i64, pool: Arc<ConnectionPool>, ws_sender: Arc<dyn WsDocumentSender>) -> Self {
        let op_sql = Arc::new(OpTableSql {});
        let rev_id_counter = RevIdCounter::new(rev_id);
        let rev_cache = Arc::new(RwLock::new(HashMap::new()));
        let remote_rev_cache = RwLock::new(VecDeque::new());
        let ack_rev_cache = Arc::new(DashSet::new());
        Self {
            doc_id: doc_id.to_owned(),
            op_sql,
            pool,
            rev_id_counter,
            ws_sender,
            rev_cache,
            ack_rev_cache,
            remote_rev_cache,
            save_operation: RwLock::new(None),
        }
    }

    pub fn next_compose_revision<F>(&self, mut f: F)
    where
        F: FnMut(&Revision) -> Result<(), DocError>,
    {
        if let Some(rev) = self.remote_rev_cache.write().pop_front() {
            match f(&rev) {
                Ok(_) => {},
                Err(e) => {
                    log::error!("{}", e);
                    self.remote_rev_cache.write().push_front(rev);
                },
            }
        }
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    pub fn add_revision(&self, revision: Revision) -> Result<(), DocError> {
        self.rev_cache.write().insert(revision.rev_id, revision.clone());
        self.save_revisions();
        match revision.ty {
            RevType::Local => match self.ws_sender.send(revision.into()) {
                Ok(_) => {},
                Err(e) => {
                    log::error!("Send delta failed: {:?}", e);
                },
            },
            RevType::Remote => {
                self.remote_rev_cache.write().push_back(revision);
            },
        }

        Ok(())
    }

    pub fn ack(&self, rev_id: i64) -> Result<(), DocError> {
        log::debug!("Receive rev_id: {} acked", rev_id);
        self.ack_rev_cache.insert(rev_id);
        self.update_revisions();
        Ok(())
    }

    pub fn next_rev_id(&self) -> (i64, i64) {
        let cur = self.rev_id_counter.value();
        let next = self.rev_id_counter.next();
        (cur, next)
    }

    pub fn rev_id(&self) -> i64 { self.rev_id_counter.value() }

    pub fn send_rev_with_range(&self, range: RevisionRange) -> Result<(), DocError> {
        debug_assert!(&range.doc_id == &self.doc_id);

        unimplemented!()
    }

    fn save_revisions(&self) {
        let op_sql = self.op_sql.clone();
        let pool = self.pool.clone();
        let mut write_guard = self.save_operation.write();
        if let Some(handler) = write_guard.take() {
            handler.abort();
        }

        let rev_cache = self.rev_cache.clone();
        let ack_rev_cache = self.ack_rev_cache.clone();
        let ids = self.rev_cache.read().keys().map(|v| v.clone()).collect::<Vec<i64>>();
        *write_guard = Some(tokio::spawn(async move {
            tokio::time::sleep(Duration::from_millis(300)).await;

            let revisions = rev_cache
                .read()
                .values()
                .map(|v| {
                    let state = match ack_rev_cache.contains(&v.rev_id) {
                        true => RevState::Acked,
                        false => RevState::Local,
                    };
                    (v.clone(), state)
                })
                .collect::<Vec<(Revision, RevState)>>();

            let mut rev_cache_write = rev_cache.write();
            let conn = &*pool.get().map_err(internal_error).unwrap();
            let result = conn.immediate_transaction::<_, DocError, _>(|| {
                let _ = op_sql.create_rev_table(revisions, conn).unwrap();
                Ok(())
            });

            match result {
                Ok(_) => rev_cache_write.retain(|k, _| !ids.contains(k)),
                Err(e) => log::error!("Save revision failed: {:?}", e),
            }
        }));
    }

    fn update_revisions(&self) {
        match self.rev_cache.try_read_for(Duration::from_millis(300)) {
            None => log::warn!("try read rev_cache failed"),
            Some(read_guard) => {
                let rev_ids = self
                    .ack_rev_cache
                    .iter()
                    .flat_map(|k| match read_guard.contains_key(&k) {
                        true => None,
                        false => Some(k.clone()),
                    })
                    .collect::<Vec<i64>>();

                log::debug!("Try to update {:?} state", rev_ids);
                if rev_ids.is_empty() {
                    return;
                }

                let conn = &*self.pool.get().map_err(internal_error).unwrap();
                let result = conn.immediate_transaction::<_, DocError, _>(|| {
                    for rev_id in &rev_ids {
                        let changeset = RevChangeset {
                            doc_id: self.doc_id.clone(),
                            rev_id: rev_id.clone(),
                            state: RevState::Acked,
                        };
                        let _ = self.op_sql.update_rev_table(changeset, conn)?;
                    }
                    Ok(())
                });

                match result {
                    Ok(_) => {
                        rev_ids.iter().for_each(|rev_id| {
                            self.ack_rev_cache.remove(rev_id);
                        });
                    },
                    Err(e) => log::error!("Save revision failed: {:?}", e),
                }
            },
        }
    }

    fn delete_revision(&self, rev_id: i64) {
        let op_sql = self.op_sql.clone();
        let pool = self.pool.clone();
        let doc_id = self.doc_id.clone();
        tokio::spawn(async move {
            let conn = &*pool.get().map_err(internal_error).unwrap();
            let result = conn.immediate_transaction::<_, DocError, _>(|| {
                let _ = op_sql.delete_rev_table(&doc_id, rev_id, conn)?;
                Ok(())
            });

            match result {
                Ok(_) => {},
                Err(e) => log::error!("Delete revision failed: {:?}", e),
            }
        });
    }
}
