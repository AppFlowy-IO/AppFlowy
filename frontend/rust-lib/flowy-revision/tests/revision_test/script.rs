use bytes::Bytes;
use flowy_error::{FlowyError, FlowyResult};
use flowy_revision::disk::{RevisionChangeset, RevisionDiskCache, SyncRecord};
use flowy_revision::{
    RevisionCompress, RevisionManager, RevisionPersistence, RevisionSnapshotDiskCache, RevisionSnapshotInfo,
};
use flowy_sync::entities::revision::{Revision, RevisionRange};
use nanoid::nanoid;
use std::sync::Arc;

pub enum RevisionScript {
    AddLocalRevision(Revision),
    AckRevision { rev_id: i64 },
    AssertNextSyncRevisionId { rev_id: i64 },
    AssertNextSyncRevision(Option<Revision>),
}

pub struct RevisionTest {
    rev_manager: Arc<RevisionManager<RevisionConnectionMock>>,
}

impl RevisionTest {
    pub async fn new() -> Self {
        let user_id = nanoid!(10);
        let object_id = nanoid!(6);
        let persistence = RevisionPersistence::new(&user_id, &object_id, RevisionDiskCacheMock::new());
        let compress = RevisionCompressMock {};
        let snapshot = RevisionSnapshotMock {};
        let rev_manager = RevisionManager::new(&user_id, &object_id, persistence, compress, snapshot);
        Self {
            rev_manager: Arc::new(rev_manager),
        }
    }
    pub async fn run_scripts(&self, scripts: Vec<RevisionScript>) {
        for script in scripts {
            self.run_script(script).await;
        }
    }
    pub async fn run_script(&self, script: RevisionScript) {
        match script {
            RevisionScript::AddLocalRevision(revision) => {
                self.rev_manager.add_local_revision(&revision).await.unwrap();
            }
            RevisionScript::AckRevision { rev_id } => {
                //
                self.rev_manager.ack_revision(rev_id).await.unwrap()
            }
            RevisionScript::AssertNextSyncRevisionId { rev_id } => {
                //
                assert_eq!(self.rev_manager.rev_id(), rev_id)
            }
            RevisionScript::AssertNextSyncRevision(expected) => {
                let next_revision = self.rev_manager.next_sync_revision().await.unwrap();
                assert_eq!(next_revision, expected);
            }
        }
    }
}

pub struct RevisionDiskCacheMock {}

impl RevisionDiskCacheMock {
    pub fn new() -> Self {
        Self {}
    }
}

impl RevisionDiskCache<RevisionConnectionMock> for RevisionDiskCacheMock {
    type Error = FlowyError;

    fn create_revision_records(&self, revision_records: Vec<SyncRecord>) -> Result<(), Self::Error> {
        todo!()
    }

    fn get_connection(&self) -> Result<RevisionConnectionMock, Self::Error> {
        todo!()
    }

    fn read_revision_records(
        &self,
        object_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> Result<Vec<SyncRecord>, Self::Error> {
        todo!()
    }

    fn read_revision_records_with_range(
        &self,
        object_id: &str,
        range: &RevisionRange,
    ) -> Result<Vec<SyncRecord>, Self::Error> {
        todo!()
    }

    fn update_revision_record(&self, changesets: Vec<RevisionChangeset>) -> FlowyResult<()> {
        todo!()
    }

    fn delete_revision_records(&self, object_id: &str, rev_ids: Option<Vec<i64>>) -> Result<(), Self::Error> {
        todo!()
    }

    fn delete_and_insert_records(
        &self,
        object_id: &str,
        deleted_rev_ids: Option<Vec<i64>>,
        inserted_records: Vec<SyncRecord>,
    ) -> Result<(), Self::Error> {
        todo!()
    }
}

pub struct RevisionConnectionMock {}

pub struct RevisionSnapshotMock {}

impl RevisionSnapshotDiskCache for RevisionSnapshotMock {
    fn write_snapshot(&self, object_id: &str, rev_id: i64, data: Vec<u8>) -> FlowyResult<()> {
        todo!()
    }

    fn read_snapshot(&self, object_id: &str, rev_id: i64) -> FlowyResult<RevisionSnapshotInfo> {
        todo!()
    }
}

pub struct RevisionCompressMock {}

impl RevisionCompress for RevisionCompressMock {
    fn combine_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        todo!()
    }
}

pub struct RevisionMock {}

// impl std::convert::From<RevisionMock> for Revision {
//     fn from(_: RevisionMock) -> Self {}
// }
