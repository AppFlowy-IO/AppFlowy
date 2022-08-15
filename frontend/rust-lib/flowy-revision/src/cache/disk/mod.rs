mod document_impl;
mod grid_block_impl;
mod grid_impl;

pub use document_impl::*;
pub use grid_block_impl::*;
pub use grid_impl::*;

use flowy_error::FlowyResult;
use flowy_sync::entities::revision::{RevId, Revision, RevisionRange};
use std::fmt::Debug;

pub trait RevisionDiskCache: Sync + Send {
    type Error: Debug;
    fn create_revision_records(&self, revision_records: Vec<RevisionRecord>) -> Result<(), Self::Error>;

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

#[derive(Clone, Debug)]
pub struct RevisionRecord {
    pub revision: Revision,
    pub state: RevisionState,
    pub write_to_disk: bool,
}

impl RevisionRecord {
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
    pub(crate) object_id: String,
    pub(crate) rev_id: RevId,
    pub(crate) state: RevisionState,
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
