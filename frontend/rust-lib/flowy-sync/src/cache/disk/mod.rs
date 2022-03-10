mod folder_rev_impl;
mod grid_rev_impl;
mod text_block_rev_impl;

pub use folder_rev_impl::*;
pub use grid_rev_impl::*;
pub use text_block_rev_impl::*;

use crate::RevisionRecord;
use diesel::SqliteConnection;
use flowy_collaboration::entities::revision::RevisionRange;
use flowy_error::FlowyResult;
use std::fmt::Debug;

pub trait RevisionDiskCache: Sync + Send {
    type Error: Debug;
    fn create_revision_records(
        &self,
        revision_records: Vec<RevisionRecord>,
        conn: &SqliteConnection,
    ) -> Result<(), Self::Error>;

    // Read all the records if the rev_ids is None
    fn read_revision_records(
        &self,
        object_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> Result<Vec<RevisionRecord>, Self::Error>;

    // Read the revision which rev_id >= range.start && rev_id <= range.end
    fn read_revision_records_with_range(
        &self,
        object_id: &str,
        range: &RevisionRange,
    ) -> Result<Vec<RevisionRecord>, Self::Error>;

    fn update_revision_record(&self, changesets: Vec<RevisionChangeset>) -> FlowyResult<()>;

    // Delete all the records if the rev_ids is None
    fn delete_revision_records(&self, object_id: &str, rev_ids: Option<Vec<i64>>) -> Result<(), Self::Error>;

    // Delete and insert will be executed in the same transaction.
    // It deletes all the records if the deleted_rev_ids is None and then insert the new records
    fn delete_and_insert_records(
        &self,
        object_id: &str,
        deleted_rev_ids: Option<Vec<i64>>,
        inserted_records: Vec<RevisionRecord>,
    ) -> Result<(), Self::Error>;
}
