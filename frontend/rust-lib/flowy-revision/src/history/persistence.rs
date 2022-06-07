use crate::history::RevisionHistoryDiskCache;
use flowy_error::FlowyError;
use flowy_sync::entities::revision::Revision;

pub struct SQLiteRevisionHistoryPersistence {}

impl SQLiteRevisionHistoryPersistence {
    pub fn new() -> Self {
        Self {}
    }
}

impl RevisionHistoryDiskCache for SQLiteRevisionHistoryPersistence {
    type Error = FlowyError;

    fn save_revision(&self, revision: Revision) -> Result<(), Self::Error> {
        todo!()
    }
}

struct RevisionHistorySql();
impl RevisionHistorySql {}
