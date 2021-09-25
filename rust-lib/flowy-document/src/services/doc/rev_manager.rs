use crate::{
    entities::{
        doc::Revision,
        ws::{WsDataType, WsDocumentData},
    },
    errors::{internal_error, DocError},
    services::{
        util::{bytes_to_rev_id, RevIdCounter},
        ws::{WsDocumentHandler, WsDocumentSender},
    },
    sql_tables::{OpTable, OpTableSql},
};
use bytes::Bytes;
use flowy_database::ConnectionPool;
use flowy_infra::future::wrap_future;
use flowy_ot::core::Delta;
use parking_lot::RwLock;
use std::{collections::BTreeMap, sync::Arc};
use tokio::sync::{futures::Notified, Notify};

pub struct RevisionManager {
    doc_id: String,
    op_sql: Arc<OpTableSql>,
    pool: Arc<ConnectionPool>,
    rev_id_counter: RevIdCounter,
    ws_sender: Arc<dyn WsDocumentSender>,
    rev_cache: RwLock<BTreeMap<i64, Revision>>,
    notify: Notify,
}

impl RevisionManager {
    pub fn new(
        doc_id: &str,
        rev_id: i64,
        op_sql: Arc<OpTableSql>,
        pool: Arc<ConnectionPool>,
        ws_sender: Arc<dyn WsDocumentSender>,
    ) -> Self {
        let rev_id_counter = RevIdCounter::new(rev_id);
        let rev_cache = RwLock::new(BTreeMap::new());
        Self {
            doc_id: doc_id.to_owned(),
            op_sql,
            pool,
            rev_id_counter,
            ws_sender,
            rev_cache,
            notify: Notify::new(),
        }
    }

    pub fn next_compose_delta(&self) -> Option<Delta> {
        // let delta = Delta::from_bytes(revision.delta)?;
        //
        // log::debug!("Remote delta: {:?}", delta);
    }

    pub fn notified(&self) -> Notified { self.notify.notified() }

    pub fn next_rev(&self) -> (i64, i64) {
        let cur = self.rev_id_counter.value();
        let next = self.rev_id_counter.next();
        (cur, next)
    }

    pub fn rev(&self) -> i64 { self.rev_id_counter.value() }

    pub fn add_local(&self, revision: Revision) -> Result<(), DocError> {
        self.rev_cache.write().insert(revision.rev_id, revision.clone());
        match self.ws_sender.send(revision.into()) {
            Ok(_) => {},
            Err(e) => {
                log::error!("Send delta failed: {:?}", e);
            },
        }
        // self.save_revision(revision.clone());
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    pub fn add_remote(&self, revision: Revision) -> Result<(), DocError> {
        self.rev_cache.write().insert(revision.rev_id, revision);
        // self.save_revision(revision.clone());
        self.notify.notify_waiters();
        Ok(())
    }

    pub fn remove(&self, rev_id: i64) -> Result<(), DocError> {
        self.rev_cache.write().remove(&rev_id);
        // self.delete_revision(rev_id);
        Ok(())
    }

    fn save_revision(&self, revision: Revision) {
        let op_sql = self.op_sql.clone();
        let pool = self.pool.clone();
        tokio::spawn(async move {
            let conn = &*pool.get().map_err(internal_error).unwrap();
            let result = conn.immediate_transaction::<_, DocError, _>(|| {
                let op_table: OpTable = revision.into();
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
