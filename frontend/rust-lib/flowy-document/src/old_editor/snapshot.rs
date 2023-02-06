use flowy_error::FlowyResult;
use flowy_revision::{RevisionSnapshotData, RevisionSnapshotPersistence};

pub struct DeltaDocumentSnapshotPersistence();

impl RevisionSnapshotPersistence for DeltaDocumentSnapshotPersistence {
    fn write_snapshot(&self, rev_id: i64, data: Vec<u8>) -> FlowyResult<()> {
        Ok(())
    }

    fn read_snapshot(&self, rev_id: i64) -> FlowyResult<Option<RevisionSnapshotData>> {
        Ok(None)
    }

    fn read_last_snapshot(&self) -> FlowyResult<Option<RevisionSnapshotData>> {
        Ok(None)
    }
}
