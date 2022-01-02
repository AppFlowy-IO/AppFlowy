use crate::services::doc::revision::RevisionRecord;

use crate::sql_tables::{RevisionChangeset, RevisionTableSql};
use diesel::SqliteConnection;
use flowy_collaboration::entities::revision::RevisionRange;
use flowy_database::ConnectionPool;
use flowy_error::{internal_error, FlowyError, FlowyResult};
use std::{fmt::Debug, sync::Arc};

pub trait RevisionDiskCache: Sync + Send {
    type Error: Debug;
    fn write_revision_records(
        &self,
        revisions: Vec<RevisionRecord>,
        conn: &SqliteConnection,
    ) -> Result<(), Self::Error>;

    // Read all the records if the rev_ids is None
    fn read_revision_records(
        &self,
        doc_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> Result<Vec<RevisionRecord>, Self::Error>;

    fn read_revision_records_with_range(
        &self,
        doc_id: &str,
        range: &RevisionRange,
    ) -> Result<Vec<RevisionRecord>, Self::Error>;

    fn update_revision_record(&self, changesets: Vec<RevisionChangeset>) -> FlowyResult<()>;

    // Delete all the records if the rev_ids is None
    fn delete_revision_records(
        &self,
        doc_id: &str,
        rev_ids: Option<Vec<i64>>,
        conn: &SqliteConnection,
    ) -> Result<(), Self::Error>;

    fn db_pool(&self) -> Arc<ConnectionPool>;
}

pub(crate) struct Persistence {
    user_id: String,
    pub(crate) pool: Arc<ConnectionPool>,
}

impl RevisionDiskCache for Persistence {
    type Error = FlowyError;

    fn write_revision_records(
        &self,
        revisions: Vec<RevisionRecord>,
        conn: &SqliteConnection,
    ) -> Result<(), Self::Error> {
        let _ = RevisionTableSql::create(revisions, conn)?;
        Ok(())
    }

    fn read_revision_records(
        &self,
        doc_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> Result<Vec<RevisionRecord>, Self::Error> {
        let conn = self.pool.get().map_err(internal_error)?;
        let records = RevisionTableSql::read(&self.user_id, doc_id, rev_ids, &*conn)?;
        Ok(records)
    }

    fn read_revision_records_with_range(
        &self,
        doc_id: &str,
        range: &RevisionRange,
    ) -> Result<Vec<RevisionRecord>, Self::Error> {
        let conn = &*self.pool.get().map_err(internal_error)?;
        let revisions = RevisionTableSql::read_with_range(&self.user_id, doc_id, range.clone(), conn)?;
        Ok(revisions)
    }

    fn update_revision_record(&self, changesets: Vec<RevisionChangeset>) -> FlowyResult<()> {
        let conn = &*self.pool.get().map_err(internal_error)?;
        let _ = conn.immediate_transaction::<_, FlowyError, _>(|| {
            for changeset in changesets {
                let _ = RevisionTableSql::update(changeset, conn)?;
            }
            Ok(())
        })?;
        Ok(())
    }

    fn delete_revision_records(
        &self,
        doc_id: &str,
        rev_ids: Option<Vec<i64>>,
        conn: &SqliteConnection,
    ) -> Result<(), Self::Error> {
        let _ = RevisionTableSql::delete(doc_id, rev_ids, conn)?;
        Ok(())
    }

    fn db_pool(&self) -> Arc<ConnectionPool> { self.pool.clone() }
}

impl Persistence {
    pub(crate) fn new(user_id: &str, pool: Arc<ConnectionPool>) -> Self {
        Self {
            user_id: user_id.to_owned(),
            pool,
        }
    }
}
