use bytes::Bytes;
use flowy_error::{FlowyError, FlowyResult};
use flowy_revision::disk::{RevisionChangeset, RevisionDiskCache, SyncRecord};
use flowy_revision::{
    RevisionManager, RevisionMergeable, RevisionPersistence, RevisionPersistenceConfiguration,
    RevisionSnapshotDiskCache, RevisionSnapshotInfo,
};
use flowy_sync::entities::revision::{Revision, RevisionRange};
use flowy_sync::util::md5;
use nanoid::nanoid;
use parking_lot::RwLock;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use std::time::Duration;

pub enum RevisionScript {
    AddLocalRevision {
        content: String,
        base_rev_id: i64,
        rev_id: i64,
    },
    AckRevision {
        rev_id: i64,
    },
    AssertNextSyncRevisionId {
        rev_id: Option<i64>,
    },
    AssertNumberOfSyncRevisions {
        num: usize,
    },
    AssertNextSyncRevisionContent {
        expected: String,
    },
    Wait {
        milliseconds: u64,
    },
}

pub struct RevisionTest {
    rev_manager: Arc<RevisionManager<RevisionConnectionMock>>,
}

impl RevisionTest {
    pub async fn new() -> Self {
        Self::new_with_configuration(2).await
    }

    pub async fn new_with_configuration(merge_when_excess_number_of_version: i64) -> Self {
        let user_id = nanoid!(10);
        let object_id = nanoid!(6);
        let configuration = RevisionPersistenceConfiguration::new(merge_when_excess_number_of_version as usize);
        let persistence = RevisionPersistence::new(&user_id, &object_id, RevisionDiskCacheMock::new(), configuration);
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

    pub fn next_rev_id_pair(&self) -> (i64, i64) {
        self.rev_manager.next_rev_id_pair()
    }

    pub async fn run_script(&self, script: RevisionScript) {
        match script {
            RevisionScript::AddLocalRevision {
                content,
                base_rev_id,
                rev_id,
            } => {
                let object = RevisionObjectMock::new(&content);
                let bytes = object.to_bytes();
                let md5 = md5(&bytes);
                let revision = Revision::new(
                    &self.rev_manager.object_id,
                    base_rev_id,
                    rev_id,
                    Bytes::from(bytes),
                    md5,
                );
                self.rev_manager.add_local_revision(&revision).await.unwrap();
            }
            RevisionScript::AckRevision { rev_id } => {
                //
                self.rev_manager.ack_revision(rev_id).await.unwrap()
            }
            RevisionScript::AssertNextSyncRevisionId { rev_id } => {
                assert_eq!(self.rev_manager.next_sync_rev_id().await, rev_id)
            }
            RevisionScript::AssertNumberOfSyncRevisions { num } => {
                assert_eq!(self.rev_manager.number_of_sync_revisions(), num)
            }
            RevisionScript::AssertNextSyncRevisionContent { expected } => {
                //
                let rev_id = self.rev_manager.next_sync_rev_id().await.unwrap();
                let revision = self.rev_manager.get_revision(rev_id).await.unwrap();
                let object = RevisionObjectMock::from_bytes(&revision.bytes);
                assert_eq!(object.content, expected);
            }
            RevisionScript::Wait { milliseconds } => {
                tokio::time::sleep(Duration::from_millis(milliseconds)).await;
            }
        }
    }
}

pub struct RevisionDiskCacheMock {
    records: RwLock<Vec<SyncRecord>>,
}

impl RevisionDiskCacheMock {
    pub fn new() -> Self {
        Self {
            records: RwLock::new(vec![]),
        }
    }
}

impl RevisionDiskCache<RevisionConnectionMock> for RevisionDiskCacheMock {
    type Error = FlowyError;

    fn create_revision_records(&self, revision_records: Vec<SyncRecord>) -> Result<(), Self::Error> {
        self.records.write().extend(revision_records);
        Ok(())
    }

    fn get_connection(&self) -> Result<RevisionConnectionMock, Self::Error> {
        todo!()
    }

    fn read_revision_records(
        &self,
        _object_id: &str,
        _rev_ids: Option<Vec<i64>>,
    ) -> Result<Vec<SyncRecord>, Self::Error> {
        todo!()
    }

    fn read_revision_records_with_range(
        &self,
        _object_id: &str,
        _range: &RevisionRange,
    ) -> Result<Vec<SyncRecord>, Self::Error> {
        todo!()
    }

    fn update_revision_record(&self, changesets: Vec<RevisionChangeset>) -> FlowyResult<()> {
        for changeset in changesets {
            if let Some(record) = self
                .records
                .write()
                .iter_mut()
                .find(|record| record.revision.rev_id == *changeset.rev_id.as_ref())
            {
                record.state = changeset.state;
            }
        }
        Ok(())
    }

    fn delete_revision_records(&self, _object_id: &str, rev_ids: Option<Vec<i64>>) -> Result<(), Self::Error> {
        match rev_ids {
            None => {}
            Some(rev_ids) => {
                for rev_id in rev_ids {
                    if let Some(index) = self
                        .records
                        .read()
                        .iter()
                        .position(|record| record.revision.rev_id == rev_id)
                    {
                        self.records.write().remove(index);
                    }
                }
            }
        }
        Ok(())
    }

    fn delete_and_insert_records(
        &self,
        _object_id: &str,
        _deleted_rev_ids: Option<Vec<i64>>,
        _inserted_records: Vec<SyncRecord>,
    ) -> Result<(), Self::Error> {
        todo!()
    }
}

pub struct RevisionConnectionMock {}

pub struct RevisionSnapshotMock {}

impl RevisionSnapshotDiskCache for RevisionSnapshotMock {
    fn write_snapshot(&self, _object_id: &str, _rev_id: i64, _data: Vec<u8>) -> FlowyResult<()> {
        todo!()
    }

    fn read_snapshot(&self, _object_id: &str, _rev_id: i64) -> FlowyResult<RevisionSnapshotInfo> {
        todo!()
    }
}

pub struct RevisionCompressMock {}

impl RevisionMergeable for RevisionCompressMock {
    fn combine_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let mut object = RevisionObjectMock::new("");
        for revision in revisions {
            let other = RevisionObjectMock::from_bytes(&revision.bytes);
            object.compose(other);
        }
        Ok(Bytes::from(object.to_bytes()))
    }
}

#[derive(Serialize, Deserialize)]
pub struct RevisionObjectMock {
    content: String,
}

impl RevisionObjectMock {
    pub fn new(s: &str) -> Self {
        Self { content: s.to_owned() }
    }

    pub fn compose(&mut self, other: RevisionObjectMock) {
        self.content.push_str(other.content.as_str());
    }

    pub fn to_bytes(&self) -> Vec<u8> {
        serde_json::to_vec(self).unwrap()
    }

    pub fn from_bytes(bytes: &[u8]) -> Self {
        serde_json::from_slice(bytes).unwrap()
    }
}
