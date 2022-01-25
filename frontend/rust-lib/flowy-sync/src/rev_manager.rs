use crate::RevisionCache;

use flowy_collaboration::{
    entities::revision::{RepeatedRevision, Revision, RevisionRange, RevisionState},
    util::{pair_rev_id_from_revisions, RevIdCounter},
};
use flowy_error::{FlowyError, FlowyResult};
use lib_infra::future::FutureResult;
use lib_ot::core::Attributes;
use std::{collections::VecDeque, sync::Arc};
use tokio::sync::RwLock;

pub trait RevisionCloudService: Send + Sync {
    fn fetch_object(&self, user_id: &str, object_id: &str) -> FutureResult<Vec<Revision>, FlowyError>;
}

pub trait RevisionObjectBuilder: Send + Sync {
    type Output;
    fn build_with_revisions(object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output>;
}

pub trait RevisionCompact: Send + Sync {
    fn compact_revisions(user_id: &str, object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Revision>;
}

pub struct RevisionManager {
    pub object_id: String,
    user_id: String,
    rev_id_counter: RevIdCounter,
    cache: Arc<RwLock<RevisionCacheCompact>>,

    #[cfg(feature = "flowy_unit_test")]
    revision_ack_notifier: tokio::sync::broadcast::Sender<i64>,
}

impl RevisionManager {
    pub fn new(user_id: &str, object_id: &str, revision_cache: Arc<RevisionCache>) -> Self {
        let rev_id_counter = RevIdCounter::new(0);
        let cache = Arc::new(RwLock::new(RevisionCacheCompact::new(object_id, revision_cache)));
        #[cfg(feature = "flowy_unit_test")]
        let (revision_ack_notifier, _) = tokio::sync::broadcast::channel(1);

        Self {
            object_id: object_id.to_string(),
            user_id: user_id.to_owned(),
            rev_id_counter,
            cache,

            #[cfg(feature = "flowy_unit_test")]
            revision_ack_notifier,
        }
    }

    pub async fn load<B, C>(&mut self, cloud: Arc<dyn RevisionCloudService>) -> FlowyResult<B::Output>
    where
        B: RevisionObjectBuilder,
        C: RevisionCompact,
    {
        let (revisions, rev_id) = RevisionLoader {
            object_id: self.object_id.clone(),
            user_id: self.user_id.clone(),
            cloud,
            cache: self.cache.clone(),
        }
        .load::<C>()
        .await?;
        self.rev_id_counter.set(rev_id);
        B::build_with_revisions(&self.object_id, revisions)
    }

    #[tracing::instrument(level = "debug", skip(self, revisions), err)]
    pub async fn reset_object(&self, revisions: RepeatedRevision) -> FlowyResult<()> {
        let rev_id = pair_rev_id_from_revisions(&revisions).1;
        let _ = self.cache.write().await.reset(revisions.into_inner()).await?;
        self.rev_id_counter.set(rev_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision), err)]
    pub async fn add_remote_revision(&self, revision: &Revision) -> Result<(), FlowyError> {
        if revision.delta_data.is_empty() {
            return Err(FlowyError::internal().context("Delta data should be empty"));
        }
        self.cache.read().await.add_ack_revision(revision).await?;
        self.rev_id_counter.set(revision.rev_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    pub async fn add_local_revision<C>(&self, revision: &Revision) -> Result<(), FlowyError>
    where
        C: RevisionCompact,
    {
        if revision.delta_data.is_empty() {
            return Err(FlowyError::internal().context("Delta data should be empty"));
        }
        self.cache.write().await.add_sync_revision::<C>(revision, true).await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub async fn ack_revision(&self, rev_id: i64) -> Result<(), FlowyError> {
        if self.cache.write().await.ack_revision(rev_id).await.is_ok() {
            #[cfg(feature = "flowy_unit_test")]
            let _ = self.revision_ack_notifier.send(rev_id);
        }
        Ok(())
    }

    pub fn rev_id(&self) -> i64 {
        self.rev_id_counter.value()
    }

    pub fn next_rev_id_pair(&self) -> (i64, i64) {
        let cur = self.rev_id_counter.value();
        let next = self.rev_id_counter.next();
        (cur, next)
    }

    pub async fn get_revisions_in_range(&self, range: RevisionRange) -> Result<Vec<Revision>, FlowyError> {
        let revisions = self.cache.read().await.revisions_in_range(range.clone()).await?;
        Ok(revisions)
    }

    pub async fn next_sync_revision(&self) -> FlowyResult<Option<Revision>> {
        Ok(self.cache.read().await.next_sync_revision().await?)
    }

    pub async fn get_revision(&self, rev_id: i64) -> Option<Revision> {
        self.cache.read().await.get(rev_id).await.map(|record| record.revision)
    }
}

#[cfg(feature = "flowy_unit_test")]
impl RevisionManager {
    pub async fn revision_cache(&self) -> Arc<RevisionCache> {
        self.cache.read().await.inner.clone()
    }
    pub fn revision_ack_receiver(&self) -> tokio::sync::broadcast::Receiver<i64> {
        self.revision_ack_notifier.subscribe()
    }
}

struct RevisionCacheCompact {
    object_id: String,
    inner: Arc<RevisionCache>,
    sync_seq: RevisionSyncSequence,
}

impl RevisionCacheCompact {
    fn new(object_id: &str, inner: Arc<RevisionCache>) -> Self {
        let sync_seq = RevisionSyncSequence::new();
        let object_id = object_id.to_owned();
        Self {
            object_id,
            inner,
            sync_seq,
        }
    }

    async fn add_ack_revision(&self, revision: &Revision) -> FlowyResult<()> {
        self.inner.add(revision.clone(), RevisionState::Ack, true).await
    }

    async fn add_sync_revision<C>(&mut self, revision: &Revision, write_to_disk: bool) -> FlowyResult<()>
    where
        C: RevisionCompact,
    {
        // match self.sync_seq.remaining_rev_ids() {
        //     None => {}
        //     Some(range) => {
        //         let revisions = self.inner.revisions_in_range(range).await?;
        //         let compact_revision = C::compact_revisions("", "", revisions)?;
        //     }
        // }

        self.inner
            .add(revision.clone(), RevisionState::Sync, write_to_disk)
            .await?;
        self.sync_seq.add_record(revision.rev_id)?;
        Ok(())
    }

    async fn ack_revision(&mut self, rev_id: i64) -> FlowyResult<()> {
        if self.sync_seq.ack(&rev_id).is_ok() {
            self.inner.ack(rev_id).await;
        }
        Ok(())
    }

    async fn next_sync_revision(&self) -> FlowyResult<Option<Revision>> {
        match self.sync_seq.next_rev_id() {
            None => Ok(None),
            Some(rev_id) => Ok(self.inner.get(rev_id).await.map(|record| record.revision)),
        }
    }

    async fn reset(&self, revisions: Vec<Revision>) -> FlowyResult<()> {
        self.inner.reset_with_revisions(&self.object_id, revisions).await?;
        Ok(())
    }
}

impl std::ops::Deref for RevisionCacheCompact {
    type Target = Arc<RevisionCache>;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

#[derive(Default)]
struct RevisionSyncSequence(VecDeque<i64>);
impl RevisionSyncSequence {
    fn new() -> Self {
        RevisionSyncSequence::default()
    }

    fn add_record(&mut self, new_rev_id: i64) -> FlowyResult<()> {
        // The last revision's rev_id must be greater than the new one.
        if let Some(rev_id) = self.0.back() {
            if *rev_id >= new_rev_id {
                return Err(
                    FlowyError::internal().context(format!("The new revision's id must be greater than {}", rev_id))
                );
            }
        }
        self.0.push_back(new_rev_id);
        Ok(())
    }

    fn ack(&mut self, rev_id: &i64) -> FlowyResult<()> {
        let cur_rev_id = self.0.front().cloned();
        if let Some(pop_rev_id) = cur_rev_id {
            if &pop_rev_id != rev_id {
                let desc = format!(
                    "The ack rev_id:{} is not equal to the current rev_id:{}",
                    rev_id, pop_rev_id
                );
                return Err(FlowyError::internal().context(desc));
            }
            let _ = self.0.pop_front();
        }
        Ok(())
    }

    fn next_rev_id(&self) -> Option<i64> {
        self.0.front().cloned()
    }

    fn remaining_rev_ids(&self) -> Option<RevisionRange> {
        if self.next_rev_id().is_some() {
            let mut seq = self.0.clone();
            let mut drained = seq.drain(1..).collect::<VecDeque<_>>();
            let start = drained.pop_front()?;
            let end = drained.pop_back().unwrap_or_else(|| start);
            Some(RevisionRange { start, end })
        } else {
            None
        }
    }
}

struct RevisionLoader {
    object_id: String,
    user_id: String,
    cloud: Arc<dyn RevisionCloudService>,
    cache: Arc<RwLock<RevisionCacheCompact>>,
}

impl RevisionLoader {
    async fn load<C>(&self) -> Result<(Vec<Revision>, i64), FlowyError>
    where
        C: RevisionCompact,
    {
        let records = self.cache.read().await.batch_get(&self.object_id)?;
        let revisions: Vec<Revision>;
        let mut rev_id = 0;
        if records.is_empty() {
            let remote_revisions = self.cloud.fetch_object(&self.user_id, &self.object_id).await?;
            for revision in &remote_revisions {
                rev_id = revision.rev_id;
                let _ = self.cache.read().await.add_ack_revision(revision).await?;
            }
            revisions = remote_revisions;
        } else {
            for record in &records {
                rev_id = record.revision.rev_id;
                if record.state == RevisionState::Sync {
                    // Sync the records if their state is RevisionState::Sync.
                    let _ = self
                        .cache
                        .write()
                        .await
                        .add_sync_revision::<C>(&record.revision, false)
                        .await?;
                }
            }
            revisions = records.into_iter().map(|record| record.revision).collect::<_>();
        }

        if let Some(revision) = revisions.last() {
            debug_assert_eq!(rev_id, revision.rev_id);
        }

        Ok((revisions, rev_id))
    }
}
