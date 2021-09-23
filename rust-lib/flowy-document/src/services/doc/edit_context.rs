use crate::{
    entities::{
        doc::{Doc, Revision},
        ws::{WsDocumentData, WsSource},
    },
    errors::{internal_error, DocError},
    services::{
        doc::Document,
        ws::{WsHandler, WsSender},
    },
    sql_tables::doc::{OpState, OpTable, OpTableSql},
};
use bytes::Bytes;
use flowy_database::ConnectionPool;
use flowy_ot::core::Delta;
use parking_lot::{lock_api::RwLockWriteGuard, RawRwLock, RwLock};
use std::{
    convert::TryInto,
    sync::{
        atomic::{AtomicI64, AtomicUsize, Ordering::SeqCst},
        Arc,
    },
};

pub(crate) struct EditDocContext {
    pub(crate) id: DocId,
    pub(crate) rev_counter: RevCounter,
    document: RwLock<Document>,
    ws_sender: Arc<dyn WsSender>,
    op_sql: Arc<OpTableSql>,
}

impl EditDocContext {
    pub(crate) fn new(doc: Doc, ws_sender: Arc<dyn WsSender>, op_sql: Arc<OpTableSql>) -> Result<Self, DocError> {
        let id: DocId = doc.id.into();
        let rev_counter = RevCounter::new(doc.revision);
        let delta: Delta = doc.data.try_into()?;
        let document = RwLock::new(Document::from_delta(delta));

        Ok(Self {
            id,
            rev_counter,
            document,
            ws_sender,
            op_sql,
        })
    }

    pub(crate) fn doc(&self) -> Doc {
        Doc {
            id: self.id.clone().into(),
            data: self.document.read().to_bytes(),
            revision: self.rev_counter.value(),
        }
    }

    pub(crate) fn apply_delta(&self, data: Bytes, pool: Arc<ConnectionPool>) -> Result<(), DocError> {
        let mut guard = self.document.write();
        let base_rev_id = self.rev_counter.value();
        let rev_id = self.rev_counter.next();
        let _ = guard.apply_delta(data.clone())?;
        let json = guard.to_json();
        drop(guard);

        // Opti: it is necessary to save the rev if send success?
        let md5 = format!("{:x}", md5::compute(json));
        let revision = Revision::new(base_rev_id, rev_id, data.to_vec(), md5);
        self.save_revision(revision.clone(), pool.clone());
        match self.ws_sender.send_data(revision.try_into()?) {
            Ok(_) => {
                // TODO: remove the rev if send success
                // let _ = self.delete_revision(rev_id, pool)?;
            },
            Err(e) => {
                log::error!("Send delta failed: {:?}", e);
            },
        }
        Ok(())
    }
}

impl EditDocContext {
    fn save_revision(&self, revision: Revision, pool: Arc<ConnectionPool>) -> Result<(), DocError> {
        let conn = &*pool.get().map_err(internal_error)?;
        conn.immediate_transaction::<_, DocError, _>(|| {
            let op_table: OpTable = revision.into();
            let _ = self.op_sql.create_op_table(op_table, conn)?;
            Ok(())
        })?;

        Ok(())
    }

    fn delete_revision(&self, rev_id: i64, pool: Arc<ConnectionPool>) -> Result<(), DocError> {
        let conn = &*pool.get().map_err(internal_error)?;
        conn.immediate_transaction::<_, DocError, _>(|| {
            let _ = self.op_sql.delete_op_table(rev_id, conn)?;
            Ok(())
        })?;
        Ok(())
    }
}

impl WsHandler for EditDocContext {
    fn receive(&self, data: WsDocumentData) {
        match data.source {
            WsSource::Delta => {},
        }
    }
}

#[derive(Debug, Clone, Eq, PartialEq, Hash)]
pub struct DocId(pub(crate) String);

impl AsRef<str> for DocId {
    fn as_ref(&self) -> &str { &self.0 }
}

impl<T> std::convert::From<T> for DocId
where
    T: ToString,
{
    fn from(s: T) -> Self { DocId(s.to_string()) }
}

impl std::convert::Into<String> for DocId {
    fn into(self) -> String { self.0.clone() }
}

#[derive(Debug)]
pub struct RevCounter(pub AtomicI64);

impl RevCounter {
    pub fn new(n: i64) -> Self { Self(AtomicI64::new(n)) }
    pub fn next(&self) -> i64 {
        let _ = self.0.fetch_add(1, SeqCst);
        self.value()
    }
    pub fn value(&self) -> i64 { self.0.load(SeqCst) }
}
