mod sql_impl;
use crate::core::revision::RevisionRecord;
use diesel::SqliteConnection;
use flowy_collaboration::entities::revision::RevisionRange;
pub use sql_impl::*;

use flowy_error::FlowyResult;
use std::fmt::Debug;

pub trait DocumentRevisionDiskCache: Sync + Send {
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

    fn reset_document(&self, doc_id: &str, revision_records: Vec<RevisionRecord>) -> Result<(), Self::Error>;
}
