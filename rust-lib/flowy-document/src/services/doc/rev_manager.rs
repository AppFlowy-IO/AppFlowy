use crate::{
    entities::doc::{RevType, Revision},
    errors::{internal_error, DocError},
    services::{
        util::RevIdCounter,
        ws::{WsDocumentHandler, WsDocumentSender},
    },
    sql_tables::{OpTableSql, RevTable},
};

use flowy_database::ConnectionPool;

use parking_lot::RwLock;
use std::{
    collections::{BTreeMap, VecDeque},
    sync::Arc,
};
use tokio::sync::{futures::Notified, Notify};

pub struct RevisionManager {
    doc_id: String,
    op_sql: Arc<OpTableSql>,
    pool: Arc<ConnectionPool>,
    rev_id_counter: RevIdCounter,
    ws_sender: Arc<dyn WsDocumentSender>,
    local_rev_cache: Arc<RwLock<BTreeMap<i64, Revision>>>,
    remote_rev_cache: RwLock<VecDeque<Revision>>,
    notify: Notify,
}

impl RevisionManager {
    pub fn new(doc_id: &str, rev_id: i64, pool: Arc<ConnectionPool>, ws_sender: Arc<dyn WsDocumentSender>) -> Self {
        let op_sql = Arc::new(OpTableSql {});
        let rev_id_counter = RevIdCounter::new(rev_id);
        let local_rev_cache = Arc::new(RwLock::new(BTreeMap::new()));
        let remote_rev_cache = RwLock::new(VecDeque::new());
        Self {
            doc_id: doc_id.to_owned(),
            op_sql,
            pool,
            rev_id_counter,
            ws_sender,
            local_rev_cache,
            remote_rev_cache,
            notify: Notify::new(),
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
        match revision.ty {
            RevType::Local => {
                self.local_rev_cache.write().insert(revision.rev_id, revision.clone());
                // self.save_revision(revision.clone());
                match self.ws_sender.send(revision.into()) {
                    Ok(_) => {},
                    Err(e) => {
                        log::error!("Send delta failed: {:?}", e);
                    },
                }
            },
            RevType::Remote => {
                self.remote_rev_cache.write().push_back(revision);
                self.notify.notify_waiters();
            },
        }

        Ok(())
    }

    pub fn remove(&self, rev_id: i64) -> Result<(), DocError> {
        self.local_rev_cache.write().remove(&rev_id);
        // self.delete_revision(rev_id);
        Ok(())
    }

    pub fn rev_notified(&self) -> Notified { self.notify.notified() }

    pub fn next_rev_id(&self) -> (i64, i64) {
        let cur = self.rev_id_counter.value();
        let next = self.rev_id_counter.next();
        (cur, next)
    }

    pub fn rev_id(&self) -> i64 { self.rev_id_counter.value() }

    fn save_revision(&self, revision: Revision) {
        let op_sql = self.op_sql.clone();
        let pool = self.pool.clone();
        tokio::spawn(async move {
            let conn = &*pool.get().map_err(internal_error).unwrap();
            let result = conn.immediate_transaction::<_, DocError, _>(|| {
                let op_table: RevTable = revision.into();
                let _ = op_sql.create_op_table(op_table, conn).unwrap();
                Ok(())
            });

            match result {
                Ok(_) => {},
                Err(e) => log::error!("Save revision failed: {:?}", e),
            }
        });
    }

    fn delete_revision(&self, rev_id: i64) {
        let op_sql = self.op_sql.clone();
        let pool = self.pool.clone();
        tokio::spawn(async move {
            let conn = &*pool.get().map_err(internal_error).unwrap();
            let result = conn.immediate_transaction::<_, DocError, _>(|| {
                let _ = op_sql.delete_op_table(rev_id, conn)?;
                Ok(())
            });

            match result {
                Ok(_) => {},
                Err(e) => log::error!("Delete revision failed: {:?}", e),
            }
        });
    }
}
