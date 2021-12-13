use crate::services::doc::revision::RevisionRecord;

use lib_ot::revision::RevisionRange;
use std::fmt::Debug;

pub trait RevisionDiskCache: Sync + Send {
    type Error: Debug;
    fn create_revisions(&self, revisions: Vec<RevisionRecord>) -> Result<(), Self::Error>;
    fn revisions_in_range(&self, doc_id: &str, range: &RevisionRange) -> Result<Vec<RevisionRecord>, Self::Error>;
    fn read_revision(&self, doc_id: &str, rev_id: i64) -> Result<Option<RevisionRecord>, Self::Error>;
    fn read_revisions(&self, doc_id: &str) -> Result<Vec<RevisionRecord>, Self::Error>;
}
