use crate::{RevisionCache, RevisionRecord};
use dashmap::DashMap;
use flowy_collaboration::{
    entities::revision::{RepeatedRevision, Revision, RevisionRange, RevisionState},
    util::{pair_rev_id_from_revisions, RevIdCounter},
};
use flowy_error::{FlowyError, FlowyResult};
use futures_util::{future, stream, stream::StreamExt};
use lib_infra::future::FutureResult;
use std::{collections::VecDeque, sync::Arc};

use tokio::sync::{broadcast, RwLock};

pub trait RevisionCloudService: Send + Sync {
    fn fetch_object(&self, user_id: &str, object_id: &str) -> FutureResult<Vec<Revision>, FlowyError>;
}

pub trait RevisionObjectBuilder: Send + Sync {
    type Output;
    fn build_with_revisions(object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output>;
}

pub struct RevisionManager {
    pub object_id: String,
    user_id: String,
    rev_id_counter: RevIdCounter,
    revision_cache: Arc<RevisionCache>,
    revision_sync_seq: Arc<RevisionSyncSequence>,

    #[cfg(feature = "flowy_unit_test")]
    revision_ack_notifier: broadcast::Sender<i64>,
}

impl RevisionManager {
    pub fn new(user_id: &str, object_id: &str, revision_cache: Arc<RevisionCache>) -> Self {
        let rev_id_counter = RevIdCounter::new(0);
        let revision_sync_seq = Arc::new(RevisionSyncSequence::new());
        #[cfg(feature = "flowy_unit_test")]
        let (revision_ack_notifier, _) = broadcast::channel(1);

        Self {
            object_id: object_id.to_string(),
            user_id: user_id.to_owned(),
            rev_id_counter,
            revision_cache,
            revision_sync_seq,

            #[cfg(feature = "flowy_unit_test")]
            revision_ack_notifier,
        }
    }

    pub async fn load<Builder>(&mut self, cloud: Arc<dyn RevisionCloudService>) -> FlowyResult<Builder::Output>
    where
        Builder: RevisionObjectBuilder,
    {
        let revisions = RevisionLoader {
            object_id: self.object_id.clone(),
            user_id: self.user_id.clone(),
            cloud,
            revision_cache: self.revision_cache.clone(),
            revision_sync_seq: self.revision_sync_seq.clone(),
        }
        .load()
        .await?;
        Builder::build_with_revisions(&self.object_id, revisions)
    }

    #[tracing::instrument(level = "debug", skip(self, revisions), err)]
    pub async fn reset_object(&self, revisions: RepeatedRevision) -> FlowyResult<()> {
        let rev_id = pair_rev_id_from_revisions(&revisions).1;
        let _ = self
            .revision_cache
            .reset_with_revisions(&self.object_id, revisions.into_inner())
            .await?;
        self.rev_id_counter.set(rev_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision), err)]
    pub async fn add_remote_revision(&self, revision: &Revision) -> Result<(), FlowyError> {
        if revision.delta_data.is_empty() {
            return Err(FlowyError::internal().context("Delta data should be empty"));
        }
        let _ = self
            .revision_cache
            .add(revision.clone(), RevisionState::Ack, true)
            .await?;
        self.rev_id_counter.set(revision.rev_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    pub async fn add_local_revision(&self, revision: &Revision) -> Result<(), FlowyError> {
        if revision.delta_data.is_empty() {
            return Err(FlowyError::internal().context("Delta data should be empty"));
        }

        let record = self
            .revision_cache
            .add(revision.clone(), RevisionState::Sync, true)
            .await?;
        self.revision_sync_seq.add_revision_record(record).await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub async fn ack_revision(&self, rev_id: i64) -> Result<(), FlowyError> {
        if self.revision_sync_seq.ack(&rev_id).await.is_ok() {
            self.revision_cache.ack(rev_id).await;

            #[cfg(feature = "flowy_unit_test")]
            let _ = self.revision_ack_notifier.send(rev_id);
        }
        Ok(())
    }

    pub fn rev_id(&self) -> i64 { self.rev_id_counter.value() }

    pub fn set_rev_id(&self, rev_id: i64) { self.rev_id_counter.set(rev_id); }

    pub fn next_rev_id_pair(&self) -> (i64, i64) {
        let cur = self.rev_id_counter.value();
        let next = self.rev_id_counter.next();
        (cur, next)
    }

    pub async fn get_revisions_in_range(&self, range: RevisionRange) -> Result<Vec<Revision>, FlowyError> {
        debug_assert!(range.object_id == self.object_id);
        let revisions = self.revision_cache.revisions_in_range(range.clone()).await?;
        Ok(revisions)
    }

    pub fn next_sync_revision(&self) -> FutureResult<Option<Revision>, FlowyError> {
        let revision_sync_seq = self.revision_sync_seq.clone();
        let revision_cache = self.revision_cache.clone();
        FutureResult::new(async move {
            match revision_sync_seq.next_sync_revision_record().await {
                None => match revision_sync_seq.next_sync_rev_id().await {
                    None => Ok(None),
                    Some(rev_id) => Ok(revision_cache.get(rev_id).await.map(|record| record.revision)),
                },
                Some((_, record)) => Ok(Some(record.revision)),
            }
        })
    }

    pub async fn latest_revision(&self) -> Revision { self.revision_cache.latest_revision().await }

    pub async fn get_revision(&self, rev_id: i64) -> Option<Revision> {
        self.revision_cache.get(rev_id).await.map(|record| record.revision)
    }
}

struct RevisionSyncSequence {
    revs_map: Arc<DashMap<i64, RevisionRecord>>,
    local_revs: Arc<RwLock<VecDeque<i64>>>,
}

impl std::default::Default for RevisionSyncSequence {
    fn default() -> Self {
        let local_revs = Arc::new(RwLock::new(VecDeque::new()));
        RevisionSyncSequence {
            revs_map: Arc::new(DashMap::new()),
            local_revs,
        }
    }
}

impl RevisionSyncSequence {
    fn new() -> Self { RevisionSyncSequence::default() }

    async fn add_revision_record(&self, record: RevisionRecord) -> FlowyResult<()> {
        if !record.state.is_need_sync() {
            return Ok(());
        }

        // The last revision's rev_id must be greater than the new one.
        if let Some(rev_id) = self.local_revs.read().await.back() {
            if *rev_id >= record.revision.rev_id {
                return Err(
                    FlowyError::internal().context(format!("The new revision's id must be greater than {}", rev_id))
                );
            }
        }
        self.local_revs.write().await.push_back(record.revision.rev_id);
        self.revs_map.insert(record.revision.rev_id, record);
        Ok(())
    }

    async fn ack(&self, rev_id: &i64) -> FlowyResult<()> {
        if let Some(pop_rev_id) = self.next_sync_rev_id().await {
            if &pop_rev_id != rev_id {
                let desc = format!(
                    "The ack rev_id:{} is not equal to the current rev_id:{}",
                    rev_id, pop_rev_id
                );
                return Err(FlowyError::internal().context(desc));
            }

            self.revs_map.remove(&pop_rev_id);
            let _ = self.local_revs.write().await.pop_front();
        }
        Ok(())
    }

    async fn next_sync_revision_record(&self) -> Option<(i64, RevisionRecord)> {
        match self.local_revs.read().await.front() {
            None => None,
            Some(rev_id) => self.revs_map.get(rev_id).map(|r| (*r.key(), r.value().clone())),
        }
    }

    async fn next_sync_rev_id(&self) -> Option<i64> { self.local_revs.read().await.front().copied() }
}

struct RevisionLoader {
    object_id: String,
    user_id: String,
    cloud: Arc<dyn RevisionCloudService>,
    revision_cache: Arc<RevisionCache>,
    revision_sync_seq: Arc<RevisionSyncSequence>,
}

impl RevisionLoader {
    async fn load(&self) -> Result<Vec<Revision>, FlowyError> {
        let records = self.revision_cache.batch_get(&self.object_id)?;
        let revisions: Vec<Revision>;
        if records.is_empty() {
            let remote_revisions = self.cloud.fetch_object(&self.user_id, &self.object_id).await?;
            for revision in &remote_revisions {
                let _ = self
                    .revision_cache
                    .add(revision.clone(), RevisionState::Ack, true)
                    .await?;
            }
            revisions = remote_revisions;
        } else {
            stream::iter(records.clone())
                .filter(|record| future::ready(record.state == RevisionState::Sync))
                .for_each(|record| async move {
                    let f = || async {
                        // Sync the records if their state is RevisionState::Local.
                        let _ = self.revision_sync_seq.add_revision_record(record.clone()).await?;
                        let _ = self.revision_cache.add(record.revision, record.state, false).await?;
                        Ok::<(), FlowyError>(())
                    };
                    match f().await {
                        Ok(_) => {},
                        Err(e) => tracing::error!("[RevisionLoader]: {}", e),
                    }
                })
                .await;
            revisions = records.into_iter().map(|record| record.revision).collect::<_>();
        }

        Ok(revisions)
    }
}

#[cfg(feature = "flowy_unit_test")]
impl RevisionSyncSequence {
    #[allow(dead_code)]
    pub fn revs_map(&self) -> Arc<DashMap<i64, RevisionRecord>> { self.revs_map.clone() }
    #[allow(dead_code)]
    pub fn pending_revs(&self) -> Arc<RwLock<VecDeque<i64>>> { self.local_revs.clone() }
}

#[cfg(feature = "flowy_unit_test")]
impl RevisionManager {
    pub fn revision_cache(&self) -> Arc<RevisionCache> { self.revision_cache.clone() }
    pub fn revision_ack_receiver(&self) -> broadcast::Receiver<i64> { self.revision_ack_notifier.subscribe() }
}
