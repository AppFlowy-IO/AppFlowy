use crate::rev_queue::{RevCommand, RevCommandSender, RevQueue};
use crate::{
    RevisionPersistence, RevisionSnapshot, RevisionSnapshotController, RevisionSnapshotDiskCache,
    WSDataProviderDataSource,
};
use bytes::Bytes;
use flowy_error::{internal_error, FlowyError, FlowyResult};
use flowy_http_model::revision::{Revision, RevisionRange};
use flowy_http_model::util::md5;
use lib_infra::future::FutureResult;
use std::sync::atomic::AtomicI64;
use std::sync::atomic::Ordering::SeqCst;
use std::sync::Arc;
use tokio::sync::{mpsc, oneshot};

pub trait RevisionCloudService: Send + Sync {
    /// Read the object's revision from remote
    /// Returns a list of revisions that used to build the object
    /// # Arguments
    ///
    /// * `user_id`: the id of the user
    /// * `object_id`: the id of the object
    ///
    fn fetch_object(&self, user_id: &str, object_id: &str) -> FutureResult<Vec<Revision>, FlowyError>;
}

pub trait RevisionObjectDeserializer: Send + Sync {
    type Output;
    /// Deserialize the list of revisions into an concrete object type.
    ///
    /// # Arguments
    ///
    /// * `object_id`: the id of the object
    /// * `revisions`: a list of revisions that represent the object
    ///
    fn deserialize_revisions(object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output>;
}

pub trait RevisionObjectSerializer: Send + Sync {
    /// Serialize a list of revisions into one in `Bytes` format
    ///
    /// * `revisions`: a list of revisions will be serialized to `Bytes`
    ///
    fn combine_revisions(revisions: Vec<Revision>) -> FlowyResult<Bytes>;
}

/// `RevisionCompress` is used to compress multiple revisions into one revision
///
pub trait RevisionMergeable: Send + Sync {
    fn merge_revisions(&self, _user_id: &str, object_id: &str, mut revisions: Vec<Revision>) -> FlowyResult<Revision> {
        if revisions.is_empty() {
            return Err(FlowyError::internal().context("Can't compact the empty revisions"));
        }

        if revisions.len() == 1 {
            return Ok(revisions.pop().unwrap());
        }

        let first_revision = revisions.first().unwrap();
        let last_revision = revisions.last().unwrap();

        let (base_rev_id, rev_id) = first_revision.pair_rev_id();
        let md5 = last_revision.md5.clone();
        let bytes = self.combine_revisions(revisions)?;
        Ok(Revision::new(object_id, base_rev_id, rev_id, bytes, md5))
    }

    fn combine_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes>;
}

pub struct RevisionManager<Connection> {
    pub object_id: String,
    user_id: String,
    rev_id_counter: Arc<RevIdCounter>,
    rev_persistence: Arc<RevisionPersistence<Connection>>,
    rev_snapshot: Arc<RevisionSnapshotController>,
    rev_compress: Arc<dyn RevisionMergeable>,
    #[cfg(feature = "flowy_unit_test")]
    rev_ack_notifier: tokio::sync::broadcast::Sender<i64>,
    rev_queue: RevCommandSender,
}

impl<Connection: 'static> RevisionManager<Connection> {
    pub fn new<SP, C>(
        user_id: &str,
        object_id: &str,
        rev_persistence: RevisionPersistence<Connection>,
        rev_compress: C,
        snapshot_persistence: SP,
    ) -> Self
    where
        SP: 'static + RevisionSnapshotDiskCache,
        C: 'static + RevisionMergeable,
    {
        let rev_id_counter = Arc::new(RevIdCounter::new(0));
        let rev_compress = Arc::new(rev_compress);
        let rev_persistence = Arc::new(rev_persistence);
        let rev_snapshot = RevisionSnapshotController::new(user_id, object_id, snapshot_persistence);
        let (rev_queue, receiver) = mpsc::channel(1000);
        let queue = RevQueue::new(
            object_id.to_owned(),
            rev_id_counter.clone(),
            rev_persistence.clone(),
            rev_compress.clone(),
            receiver,
        );
        tokio::spawn(queue.run());
        Self {
            object_id: object_id.to_string(),
            user_id: user_id.to_owned(),
            rev_id_counter,
            rev_persistence,
            rev_snapshot: Arc::new(rev_snapshot),
            rev_compress,
            #[cfg(feature = "flowy_unit_test")]
            rev_ack_notifier: tokio::sync::broadcast::channel(1).0,
            rev_queue,
        }
    }

    #[tracing::instrument(level = "debug", skip_all, fields(deserializer, object) err)]
    pub async fn initialize<B>(&mut self, _cloud: Option<Arc<dyn RevisionCloudService>>) -> FlowyResult<B::Output>
    where
        B: RevisionObjectDeserializer,
    {
        let revision_records = self.rev_persistence.load_all_records(&self.object_id)?;
        tracing::Span::current().record("object", &self.object_id.as_str());
        tracing::Span::current().record("deserializer", &std::any::type_name::<B>());
        let revisions: Vec<Revision> = revision_records.iter().map(|record| record.revision.clone()).collect();
        let current_rev_id = revisions.last().as_ref().map(|revision| revision.rev_id).unwrap_or(0);
        match B::deserialize_revisions(&self.object_id, revisions) {
            Ok(object) => {
                let _ = self.rev_persistence.sync_revision_records(&revision_records).await?;
                self.rev_id_counter.set(current_rev_id);
                Ok(object)
            }
            Err(err) => match self.restore_from_snapshot::<B>(current_rev_id) {
                None => Err(err),
                Some((object, snapshot_rev)) => {
                    let snapshot_rev_id = snapshot_rev.rev_id;
                    let _ = self.rev_persistence.reset(vec![snapshot_rev]).await;
                    // revision_records.retain(|record| record.revision.rev_id <= snapshot_rev_id);
                    // let _ = self.rev_persistence.sync_revision_records(&revision_records).await?;
                    self.rev_id_counter.set(snapshot_rev_id);
                    Ok(object)
                }
            },
        }
    }

    pub async fn close(&self) {
        let _ = self.rev_persistence.compact_lagging_revisions(&self.rev_compress).await;
    }

    pub async fn generate_snapshot(&self) {
        match self
            .load_revisions()
            .await
            .and_then(|revisions| self.rev_compress.combine_revisions(revisions))
        {
            Ok(bytes) => {
                let rev_id = self.rev_id_counter.value();
                if let Err(e) = self.rev_snapshot.write_snapshot(rev_id, bytes.to_vec()) {
                    tracing::error!("Save snapshot failed: {}", e);
                }
            }
            Err(e) => {
                tracing::error!("Generate snapshot data failed: {}", e);
            }
        }
    }

    pub async fn read_snapshot(&self, rev_id: Option<i64>) -> FlowyResult<Option<RevisionSnapshot>> {
        match rev_id {
            None => self.rev_snapshot.read_last_snapshot(),
            Some(rev_id) => self.rev_snapshot.read_snapshot(rev_id),
        }
    }

    /// Find the nearest revision base on the passed-in rev_id
    fn restore_from_snapshot<B>(&self, rev_id: i64) -> Option<(B::Output, Revision)>
    where
        B: RevisionObjectDeserializer,
    {
        tracing::trace!("Try to find if {} has snapshot", self.object_id);
        let snapshot = self.rev_snapshot.read_last_snapshot().ok()??;
        let snapshot_rev_id = snapshot.rev_id;
        let revision = Revision::new(
            &self.object_id,
            snapshot.base_rev_id,
            snapshot.rev_id,
            snapshot.data,
            "".to_owned(),
        );
        tracing::trace!(
            "Try to restore from snapshot: {}, {}",
            snapshot.base_rev_id,
            snapshot.rev_id
        );
        let object = B::deserialize_revisions(&self.object_id, vec![revision.clone()]).ok()?;
        tracing::trace!(
            "Restore {} from snapshot with rev_id: {}",
            self.object_id,
            snapshot_rev_id
        );

        Some((object, revision))
    }

    pub async fn load_revisions(&self) -> FlowyResult<Vec<Revision>> {
        let revisions = RevisionLoader {
            object_id: self.object_id.clone(),
            user_id: self.user_id.clone(),
            cloud: None,
            rev_persistence: self.rev_persistence.clone(),
        }
        .load_revisions()
        .await?;
        Ok(revisions)
    }

    #[tracing::instrument(level = "debug", skip(self, revisions), err)]
    pub async fn reset_object(&self, revisions: Vec<Revision>) -> FlowyResult<()> {
        let rev_id = pair_rev_id_from_revisions(&revisions).1;
        let _ = self.rev_persistence.reset(revisions).await?;
        self.rev_id_counter.set(rev_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision), err)]
    pub async fn add_remote_revision(&self, revision: &Revision) -> Result<(), FlowyError> {
        if revision.bytes.is_empty() {
            return Err(FlowyError::internal().context("Remote revisions is empty"));
        }

        let _ = self.rev_persistence.add_ack_revision(revision).await?;
        self.rev_id_counter.set(revision.rev_id);
        Ok(())
    }

    /// Adds the revision that generated by user editing
    // #[tracing::instrument(level = "trace", skip_all, err)]
    pub async fn add_local_revision(&self, data: Bytes, object_md5: String) -> Result<i64, FlowyError> {
        if data.is_empty() {
            return Err(FlowyError::internal().context("The data of the revisions is empty"));
        }
        let (ret, rx) = oneshot::channel();
        self.rev_queue
            .send(RevCommand::RevisionData { data, object_md5, ret })
            .await
            .map_err(internal_error)?;
        rx.await.map_err(internal_error)?
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub async fn ack_revision(&self, rev_id: i64) -> Result<(), FlowyError> {
        if self.rev_persistence.ack_revision(rev_id).await.is_ok() {
            #[cfg(feature = "flowy_unit_test")]
            let _ = self.rev_ack_notifier.send(rev_id);
        }
        Ok(())
    }

    /// Returns the current revision id
    pub fn rev_id(&self) -> i64 {
        self.rev_id_counter.value()
    }

    pub async fn next_sync_rev_id(&self) -> Option<i64> {
        self.rev_persistence.next_sync_rev_id().await
    }

    pub fn next_rev_id_pair(&self) -> (i64, i64) {
        let cur = self.rev_id_counter.value();
        let next = self.rev_id_counter.next_id();
        (cur, next)
    }

    pub fn number_of_sync_revisions(&self) -> usize {
        self.rev_persistence.number_of_sync_records()
    }

    pub fn number_of_revisions_in_disk(&self) -> usize {
        self.rev_persistence.number_of_records_in_disk()
    }

    pub async fn get_revisions_in_range(&self, range: RevisionRange) -> Result<Vec<Revision>, FlowyError> {
        let revisions = self.rev_persistence.revisions_in_range(&range).await?;
        Ok(revisions)
    }

    pub async fn next_sync_revision(&self) -> FlowyResult<Option<Revision>> {
        self.rev_persistence.next_sync_revision().await
    }

    pub async fn get_revision(&self, rev_id: i64) -> Option<Revision> {
        self.rev_persistence.get(rev_id).await.map(|record| record.revision)
    }
}

impl<Connection: 'static> WSDataProviderDataSource for Arc<RevisionManager<Connection>> {
    fn next_revision(&self) -> FutureResult<Option<Revision>, FlowyError> {
        let rev_manager = self.clone();
        FutureResult::new(async move { rev_manager.next_sync_revision().await })
    }

    fn ack_revision(&self, rev_id: i64) -> FutureResult<(), FlowyError> {
        let rev_manager = self.clone();
        FutureResult::new(async move { (*rev_manager).ack_revision(rev_id).await })
    }

    fn current_rev_id(&self) -> i64 {
        self.rev_id()
    }
}

#[cfg(feature = "flowy_unit_test")]
impl<Connection: 'static> RevisionManager<Connection> {
    pub async fn revision_cache(&self) -> Arc<RevisionPersistence<Connection>> {
        self.rev_persistence.clone()
    }
    pub fn ack_notify(&self) -> tokio::sync::broadcast::Receiver<i64> {
        self.rev_ack_notifier.subscribe()
    }
    pub fn get_all_revision_records(&self) -> FlowyResult<Vec<crate::disk::SyncRecord>> {
        self.rev_persistence.load_all_records(&self.object_id)
    }
}

pub struct RevisionLoader<Connection> {
    pub object_id: String,
    pub user_id: String,
    pub cloud: Option<Arc<dyn RevisionCloudService>>,
    pub rev_persistence: Arc<RevisionPersistence<Connection>>,
}

impl<Connection: 'static> RevisionLoader<Connection> {
    pub async fn load_revisions(&self) -> Result<Vec<Revision>, FlowyError> {
        let records = self.rev_persistence.load_all_records(&self.object_id)?;
        let revisions = records.into_iter().map(|record| record.revision).collect::<_>();
        Ok(revisions)
    }
}

/// Represents as the md5 of the revision object after applying the
/// revision. For example, RevisionMD5 will be the md5 of the document
/// content.
#[derive(Debug, Clone)]
pub struct RevisionMD5(String);

impl RevisionMD5 {
    pub fn from_bytes<T: AsRef<[u8]>>(bytes: T) -> Result<Self, FlowyError> {
        Ok(RevisionMD5(md5(bytes)))
    }

    pub fn into_inner(self) -> String {
        self.0
    }

    pub fn is_equal(&self, s: &str) -> bool {
        self.0 == s
    }
}

impl std::convert::From<RevisionMD5> for String {
    fn from(md5: RevisionMD5) -> Self {
        md5.0
    }
}

impl std::convert::From<&str> for RevisionMD5 {
    fn from(s: &str) -> Self {
        Self(s.to_owned())
    }
}
impl std::convert::From<String> for RevisionMD5 {
    fn from(s: String) -> Self {
        Self(s)
    }
}

impl std::ops::Deref for RevisionMD5 {
    type Target = String;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl PartialEq<Self> for RevisionMD5 {
    fn eq(&self, other: &Self) -> bool {
        self.0 == other.0
    }
}

impl std::cmp::Eq for RevisionMD5 {}

fn pair_rev_id_from_revisions(revisions: &[Revision]) -> (i64, i64) {
    let mut rev_id = 0;
    revisions.iter().for_each(|revision| {
        if rev_id < revision.rev_id {
            rev_id = revision.rev_id;
        }
    });

    if rev_id > 0 {
        (rev_id - 1, rev_id)
    } else {
        (0, rev_id)
    }
}

#[derive(Debug)]
pub struct RevIdCounter(pub AtomicI64);

impl RevIdCounter {
    pub fn new(n: i64) -> Self {
        Self(AtomicI64::new(n))
    }

    pub fn next_id(&self) -> i64 {
        let _ = self.0.fetch_add(1, SeqCst);
        self.value()
    }

    pub fn value(&self) -> i64 {
        self.0.load(SeqCst)
    }

    pub fn set(&self, n: i64) {
        let _ = self.0.fetch_update(SeqCst, SeqCst, |_| Some(n));
    }
}
