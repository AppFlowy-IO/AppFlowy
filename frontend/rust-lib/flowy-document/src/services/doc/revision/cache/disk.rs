use crate::services::doc::revision::RevisionRecord;

use crate::sql_tables::RevTableSql;
use flowy_database::ConnectionPool;
use flowy_error::{internal_error, FlowyError};
use lib_ot::revision::RevisionRange;
use std::{fmt::Debug, sync::Arc};

pub trait RevisionDiskCache: Sync + Send {
    type Error: Debug;
    fn create_revisions(&self, revisions: Vec<RevisionRecord>) -> Result<(), Self::Error>;
    fn revisions_in_range(&self, doc_id: &str, range: &RevisionRange) -> Result<Vec<RevisionRecord>, Self::Error>;
    fn read_revision(&self, doc_id: &str, rev_id: i64) -> Result<Option<RevisionRecord>, Self::Error>;
    fn read_revisions(&self, doc_id: &str) -> Result<Vec<RevisionRecord>, Self::Error>;
}

pub(crate) struct Persistence {
    user_id: String,
    pub(crate) pool: Arc<ConnectionPool>,
}

impl RevisionDiskCache for Persistence {
    type Error = FlowyError;

    fn create_revisions(&self, revisions: Vec<RevisionRecord>) -> Result<(), Self::Error> {
        let conn = &*self.pool.get().map_err(internal_error)?;
        conn.immediate_transaction::<_, FlowyError, _>(|| {
            let _ = RevTableSql::create_rev_table(revisions, conn)?;
            Ok(())
        })
    }

    fn revisions_in_range(&self, doc_id: &str, range: &RevisionRange) -> Result<Vec<RevisionRecord>, Self::Error> {
        let conn = &*self.pool.get().map_err(internal_error).unwrap();
        let revisions = RevTableSql::read_rev_tables_with_range(&self.user_id, doc_id, range.clone(), conn)?;
        Ok(revisions)
    }

    fn read_revision(&self, doc_id: &str, rev_id: i64) -> Result<Option<RevisionRecord>, Self::Error> {
        let conn = self.pool.get().map_err(internal_error)?;
        let some = RevTableSql::read_rev_table(&self.user_id, doc_id, &rev_id, &*conn)?;
        Ok(some)
    }

    fn read_revisions(&self, doc_id: &str) -> Result<Vec<RevisionRecord>, Self::Error> {
        let conn = self.pool.get().map_err(internal_error)?;
        let some = RevTableSql::read_rev_tables(&self.user_id, doc_id, &*conn)?;
        Ok(some)
    }
}

impl Persistence {
    pub(crate) fn new(user_id: &str, pool: Arc<ConnectionPool>) -> Self {
        Self {
            user_id: user_id.to_owned(),
            pool,
        }
    }
}
