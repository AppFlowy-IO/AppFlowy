use crate::{
    errors::{internal_error, DocError, DocResult},
    sql_tables::{RevTableSql, SqlRevState},
};
use flowy_database::ConnectionPool;
use lib_infra::future::ResultFuture;
use lib_ot::revision::{Revision, RevisionRange};
use std::sync::Arc;
use tokio::sync::broadcast;

pub(crate) struct Persistence {
    pub(crate) rev_sql: Arc<RevTableSql>,
    pub(crate) pool: Arc<ConnectionPool>,
}

impl Persistence {
    pub(crate) fn new(pool: Arc<ConnectionPool>) -> Self {
        let rev_sql = Arc::new(RevTableSql {});
        Self { rev_sql, pool }
    }

    pub(crate) fn create_revs(&self, revisions: Vec<(Revision, SqlRevState)>) -> DocResult<()> {
        let conn = &*self.pool.get().map_err(internal_error)?;
        conn.immediate_transaction::<_, DocError, _>(|| {
            let _ = self.rev_sql.create_rev_table(revisions, conn)?;
            Ok(())
        })
    }

    pub(crate) fn read_rev_with_range(&self, doc_id: &str, range: RevisionRange) -> DocResult<Vec<Revision>> {
        let conn = &*self.pool.get().map_err(internal_error).unwrap();
        let revisions = self.rev_sql.read_rev_tables_with_range(doc_id, range, conn)?;
        Ok(revisions)
    }

    pub(crate) fn read_rev(&self, doc_id: &str, rev_id: &i64) -> DocResult<Option<Revision>> {
        let conn = self.pool.get().map_err(internal_error)?;
        let some = self.rev_sql.read_rev_table(&doc_id, rev_id, &*conn)?;
        Ok(some)
    }
}

pub trait RevisionIterator: Send + Sync {
    fn next(&self) -> ResultFuture<Option<Revision>, DocError>;
}
