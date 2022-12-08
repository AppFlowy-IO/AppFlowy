use bytes::Bytes;
use flowy_error::{internal_error, FlowyError, FlowyResult};
use flowy_revision::disk::{RevisionChangeset, RevisionDiskCache, SyncRecord};
use flowy_revision::{
    RevisionManager, RevisionMergeable, RevisionObjectDeserializer, RevisionPersistence,
    RevisionPersistenceConfiguration, RevisionSnapshot, RevisionSnapshotDiskCache, REVISION_WRITE_INTERVAL_IN_MILLIS,
};

use flowy_http_model::revision::{Revision, RevisionRange};
use flowy_http_model::util::md5;
use nanoid::nanoid;
use parking_lot::RwLock;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use std::time::Duration;

pub enum RevisionScript {
    AddLocalRevision { content: String },
    AddLocalRevision2 { content: String },
    AddInvalidLocalRevision { bytes: Vec<u8> },
    AckRevision { rev_id: i64 },
    AssertNextSyncRevisionId { rev_id: Option<i64> },
    AssertNumberOfSyncRevisions { num: usize },
    AssertNumberOfRevisionsInDisk { num: usize },
    AssertNextSyncRevisionContent { expected: String },
    WaitWhenWriteToDisk,
}

pub struct RevisionTest {
    user_id: String,
    object_id: String,
    configuration: RevisionPersistenceConfiguration,
    rev_manager: Arc<RevisionManager<RevisionConnectionMock>>,
}

impl RevisionTest {
    pub async fn new() -> Self {
        Self::new_with_configuration(2).await
    }

    pub async fn new_with_configuration(merge_threshold: i64) -> Self {
        let user_id = nanoid!(10);
        let object_id = nanoid!(6);
        let configuration = RevisionPersistenceConfiguration::new(merge_threshold as usize, false);
        let disk_cache = RevisionDiskCacheMock::new(vec![]);
        let persistence = RevisionPersistence::new(&user_id, &object_id, disk_cache, configuration.clone());
        let compress = RevisionMergeableMock {};
        let snapshot = RevisionSnapshotMock {};
        let mut rev_manager = RevisionManager::new(&user_id, &object_id, persistence, compress, snapshot);
        rev_manager.initialize::<RevisionObjectMockSerde>(None).await.unwrap();
        Self {
            user_id,
            object_id,
            configuration,
            rev_manager: Arc::new(rev_manager),
        }
    }

    pub async fn new_with_other(old_test: RevisionTest) -> Self {
        let records = old_test.rev_manager.get_all_revision_records().unwrap();
        let disk_cache = RevisionDiskCacheMock::new(records);
        let configuration = old_test.configuration;
        let persistence = RevisionPersistence::new(
            &old_test.user_id,
            &old_test.object_id,
            disk_cache,
            configuration.clone(),
        );

        let compress = RevisionMergeableMock {};
        let snapshot = RevisionSnapshotMock {};
        let mut rev_manager =
            RevisionManager::new(&old_test.user_id, &old_test.object_id, persistence, compress, snapshot);
        rev_manager.initialize::<RevisionObjectMockSerde>(None).await.unwrap();
        Self {
            user_id: old_test.user_id,
            object_id: old_test.object_id,
            configuration,
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
            RevisionScript::AddLocalRevision { content } => {
                let object = RevisionObjectMock::new(&content);
                let bytes = object.to_bytes();
                let md5 = md5(&bytes);
                self.rev_manager
                    .add_local_revision(Bytes::from(bytes), md5)
                    .await
                    .unwrap();
            }
            RevisionScript::AddLocalRevision2 { content } => {
                let object = RevisionObjectMock::new(&content);
                let bytes = object.to_bytes();
                let md5 = md5(&bytes);
                self.rev_manager
                    .add_local_revision(Bytes::from(bytes), md5)
                    .await
                    .unwrap();
            }
            RevisionScript::AddInvalidLocalRevision { bytes } => {
                let md5 = md5(&bytes);
                self.rev_manager
                    .add_local_revision(Bytes::from(bytes), md5)
                    .await
                    .unwrap();
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
            RevisionScript::AssertNumberOfRevisionsInDisk { num } => {
                assert_eq!(self.rev_manager.number_of_revisions_in_disk(), num)
            }
            RevisionScript::AssertNextSyncRevisionContent { expected } => {
                //
                let rev_id = self.rev_manager.next_sync_rev_id().await.unwrap();
                let revision = self.rev_manager.get_revision(rev_id).await.unwrap();
                let object = RevisionObjectMock::from_bytes(&revision.bytes).unwrap();
                assert_eq!(object.content, expected);
            }
            RevisionScript::WaitWhenWriteToDisk => {
                let milliseconds = 2 * REVISION_WRITE_INTERVAL_IN_MILLIS;
                tokio::time::sleep(Duration::from_millis(milliseconds)).await;
            }
        }
    }
}

pub struct RevisionDiskCacheMock {
    records: RwLock<Vec<SyncRecord>>,
}

impl RevisionDiskCacheMock {
    pub fn new(records: Vec<SyncRecord>) -> Self {
        Self {
            records: RwLock::new(records),
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
        rev_ids: Option<Vec<i64>>,
    ) -> Result<Vec<SyncRecord>, Self::Error> {
        match rev_ids {
            None => Ok(self.records.read().clone()),
            Some(rev_ids) => Ok(self
                .records
                .read()
                .iter()
                .filter(|record| rev_ids.contains(&record.revision.rev_id))
                .cloned()
                .collect::<Vec<SyncRecord>>()),
        }
    }

    fn read_revision_records_with_range(
        &self,
        _object_id: &str,
        range: &RevisionRange,
    ) -> Result<Vec<SyncRecord>, Self::Error> {
        let read_guard = self.records.read();
        let records = range
            .iter()
            .flat_map(|rev_id| {
                read_guard
                    .iter()
                    .find(|record| record.revision.rev_id == rev_id)
                    .cloned()
            })
            .collect::<Vec<SyncRecord>>();
        Ok(records)
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
    fn write_snapshot(&self, _rev_id: i64, _data: Vec<u8>) -> FlowyResult<()> {
        todo!()
    }

    fn read_snapshot(&self, _rev_id: i64) -> FlowyResult<Option<RevisionSnapshot>> {
        todo!()
    }

    fn read_last_snapshot(&self) -> FlowyResult<Option<RevisionSnapshot>> {
        Ok(None)
    }

    fn latest_snapshot_from(&self, rev_id: i64) -> FlowyResult<Option<RevisionSnapshot>> {
        todo!()
    }
}

pub struct RevisionMergeableMock {}

impl RevisionMergeable for RevisionMergeableMock {
    fn combine_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let mut object = RevisionObjectMock::new("");
        for revision in revisions {
            if let Ok(other) = RevisionObjectMock::from_bytes(&revision.bytes) {
                let _ = object.compose(other)?;
            }
        }
        Ok(Bytes::from(object.to_bytes()))
    }
}

#[derive(Serialize, Deserialize)]
pub struct InvalidRevisionObject {
    data: String,
}

impl InvalidRevisionObject {
    pub fn new() -> Self {
        InvalidRevisionObject { data: "".to_string() }
    }
    pub(crate) fn to_bytes(&self) -> Vec<u8> {
        serde_json::to_vec(self).unwrap()
    }

    // fn from_bytes(bytes: &[u8]) -> Self {
    //     serde_json::from_slice(bytes).unwrap()
    // }
}

#[derive(Serialize, Deserialize)]
pub struct RevisionObjectMock {
    content: String,
}

impl RevisionObjectMock {
    pub fn new(s: &str) -> Self {
        Self { content: s.to_owned() }
    }

    pub fn compose(&mut self, other: RevisionObjectMock) -> FlowyResult<()> {
        self.content.push_str(other.content.as_str());
        Ok(())
    }

    pub fn to_bytes(&self) -> Vec<u8> {
        serde_json::to_vec(self).unwrap()
    }

    pub fn from_bytes(bytes: &[u8]) -> FlowyResult<Self> {
        serde_json::from_slice(bytes).map_err(internal_error)
    }
}

pub struct RevisionObjectMockSerde();
impl RevisionObjectDeserializer for RevisionObjectMockSerde {
    type Output = RevisionObjectMock;

    fn deserialize_revisions(_object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let mut object = RevisionObjectMock::new("");
        if revisions.is_empty() {
            return Ok(object);
        }

        for revision in revisions {
            if let Ok(revision_object) = RevisionObjectMock::from_bytes(&revision.bytes) {
                let _ = object.compose(revision_object)?;
            }
        }

        Ok(object)
    }
}
