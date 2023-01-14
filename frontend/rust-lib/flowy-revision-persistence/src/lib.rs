mod disk_cache_impl;

use flowy_error::{FlowyError, FlowyResult};
use flowy_http_model::revision::{Revision, RevisionRange};
use std::fmt::Debug;
use std::sync::Arc;

pub trait RevisionDiskCache<Connection>: Sync + Send {
    type Error: Debug;
    fn create_revision_records(&self, revision_records: Vec<SyncRecord>) -> Result<(), Self::Error>;

    fn get_connection(&self) -> Result<Connection, Self::Error>;

    // Read all the records if the rev_ids is None
    fn read_revision_records(&self, object_id: &str, rev_ids: Option<Vec<i64>>)
        -> Result<Vec<SyncRecord>, Self::Error>;

    // Read the revision which rev_id >= range.start && rev_id <= range.end
    fn read_revision_records_with_range(
        &self,
        object_id: &str,
        range: &RevisionRange,
    ) -> Result<Vec<SyncRecord>, Self::Error>;

    fn update_revision_record(&self, changesets: Vec<RevisionChangeset>) -> FlowyResult<()>;

    // Delete all the records if the rev_ids is None
    fn delete_revision_records(&self, object_id: &str, rev_ids: Option<Vec<i64>>) -> Result<(), Self::Error>;

    // Delete and insert will be executed in the same transaction.
    // It deletes all the records if the deleted_rev_ids is None and then insert the new records
    fn delete_and_insert_records(
        &self,
        object_id: &str,
        deleted_rev_ids: Option<Vec<i64>>,
        inserted_records: Vec<SyncRecord>,
    ) -> Result<(), Self::Error>;
}

impl<T, Connection> RevisionDiskCache<Connection> for Arc<T>
where
    T: RevisionDiskCache<Connection, Error = FlowyError>,
{
    type Error = FlowyError;

    fn create_revision_records(&self, revision_records: Vec<SyncRecord>) -> Result<(), Self::Error> {
        (**self).create_revision_records(revision_records)
    }

    fn get_connection(&self) -> Result<Connection, Self::Error> {
        (**self).get_connection()
    }

    fn read_revision_records(
        &self,
        object_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> Result<Vec<SyncRecord>, Self::Error> {
        (**self).read_revision_records(object_id, rev_ids)
    }

    fn read_revision_records_with_range(
        &self,
        object_id: &str,
        range: &RevisionRange,
    ) -> Result<Vec<SyncRecord>, Self::Error> {
        (**self).read_revision_records_with_range(object_id, range)
    }

    fn update_revision_record(&self, changesets: Vec<RevisionChangeset>) -> FlowyResult<()> {
        (**self).update_revision_record(changesets)
    }

    fn delete_revision_records(&self, object_id: &str, rev_ids: Option<Vec<i64>>) -> Result<(), Self::Error> {
        (**self).delete_revision_records(object_id, rev_ids)
    }

    fn delete_and_insert_records(
        &self,
        object_id: &str,
        deleted_rev_ids: Option<Vec<i64>>,
        inserted_records: Vec<SyncRecord>,
    ) -> Result<(), Self::Error> {
        (**self).delete_and_insert_records(object_id, deleted_rev_ids, inserted_records)
    }
}

#[derive(Clone, Debug)]
pub struct SyncRecord {
    pub revision: Revision,
    pub state: RevisionState,
    pub write_to_disk: bool,
}

impl SyncRecord {
    pub fn new(revision: Revision) -> Self {
        Self {
            revision,
            state: RevisionState::Sync,
            write_to_disk: true,
        }
    }

    pub fn ack(&mut self) {
        self.state = RevisionState::Ack;
    }
}

pub struct RevisionChangeset {
    pub object_id: String,
    pub rev_id: i64,
    pub state: RevisionState,
}

/// Sync: revision is not synced to the server
/// Ack: revision is synced to the server
#[derive(Debug, Clone, Eq, PartialEq)]
pub enum RevisionState {
    Sync = 0,
    Ack = 1,
}

impl RevisionState {
    pub fn is_need_sync(&self) -> bool {
        match self {
            RevisionState::Sync => true,
            RevisionState::Ack => false,
        }
    }
}

impl AsRef<RevisionState> for RevisionState {
    fn as_ref(&self) -> &RevisionState {
        self
    }
}
