use crate::RevisionCache;
use flowy_collaboration::{
    entities::revision::{RepeatedRevision, Revision, RevisionRange, RevisionState},
    util::{pair_rev_id_from_revisions, RevIdCounter},
};
use flowy_error::{FlowyError, FlowyResult};
use lib_infra::future::FutureResult;

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
    rev_compressor: Arc<RwLock<RevisionCompressor>>,

    #[cfg(feature = "flowy_unit_test")]
    rev_ack_notifier: tokio::sync::broadcast::Sender<i64>,
}

impl RevisionManager {
    pub fn new(user_id: &str, object_id: &str, revision_cache: Arc<RevisionCache>) -> Self {
        let rev_id_counter = RevIdCounter::new(0);
        let rev_compressor = Arc::new(RwLock::new(RevisionCompressor::new(object_id, user_id, revision_cache)));
        #[cfg(feature = "flowy_unit_test")]
        let (revision_ack_notifier, _) = tokio::sync::broadcast::channel(1);

        Self {
            object_id: object_id.to_string(),
            user_id: user_id.to_owned(),
            rev_id_counter,
            rev_compressor,

            #[cfg(feature = "flowy_unit_test")]
            rev_ack_notifier: revision_ack_notifier,
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
            rev_compressor: self.rev_compressor.clone(),
        }
        .load::<C>()
        .await?;
        self.rev_id_counter.set(rev_id);
        B::build_with_revisions(&self.object_id, revisions)
    }

    #[tracing::instrument(level = "debug", skip(self, revisions), err)]
    pub async fn reset_object(&self, revisions: RepeatedRevision) -> FlowyResult<()> {
        let rev_id = pair_rev_id_from_revisions(&revisions).1;

        let write_guard = self.rev_compressor.write().await;
        let _ = write_guard.reset(revisions.into_inner()).await?;
        self.rev_id_counter.set(rev_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision), err)]
    pub async fn add_remote_revision(&self, revision: &Revision) -> Result<(), FlowyError> {
        if revision.delta_data.is_empty() {
            return Err(FlowyError::internal().context("Delta data should be empty"));
        }

        let write_guard = self.rev_compressor.write().await;
        let _ = write_guard.add_ack_revision(revision).await?;
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
        let mut write_guard = self.rev_compressor.write().await;
        let rev_id = write_guard.write_sync_revision::<C>(revision).await?;

        self.rev_id_counter.set(rev_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub async fn ack_revision(&self, rev_id: i64) -> Result<(), FlowyError> {
        if self.rev_compressor.write().await.ack_revision(rev_id).await.is_ok() {
            #[cfg(feature = "flowy_unit_test")]
            let _ = self.rev_ack_notifier.send(rev_id);
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
        let revisions = self.rev_compressor.read().await.revisions_in_range(&range).await?;
        Ok(revisions)
    }

    pub async fn next_sync_revision(&self) -> FlowyResult<Option<Revision>> {
        Ok(self.rev_compressor.read().await.next_sync_revision().await?)
    }

    pub async fn get_revision(&self, rev_id: i64) -> Option<Revision> {
        self.rev_compressor
            .read()
            .await
            .get(rev_id)
            .await
            .map(|record| record.revision)
    }
}

#[cfg(feature = "flowy_unit_test")]
impl RevisionManager {
    pub async fn revision_cache(&self) -> Arc<RevisionCache> {
        self.rev_compressor.read().await.inner.clone()
    }
    pub fn ack_notify(&self) -> tokio::sync::broadcast::Receiver<i64> {
        self.rev_ack_notifier.subscribe()
    }
}

struct RevisionCompressor {
    object_id: String,
    user_id: String,
    inner: Arc<RevisionCache>,
    sync_seq: RevisionSyncSequence,
}

impl RevisionCompressor {
    fn new(object_id: &str, user_id: &str, inner: Arc<RevisionCache>) -> Self {
        let sync_seq = RevisionSyncSequence::new();
        let object_id = object_id.to_owned();
        let user_id = user_id.to_owned();
        Self {
            object_id,
            user_id,
            inner,
            sync_seq,
        }
    }

    // Call this method to write the revisions that fetch from server to disk.
    #[tracing::instrument(level = "trace", skip(self, revision), fields(rev_id, object_id=%self.object_id), err)]
    async fn add_ack_revision(&self, revision: &Revision) -> FlowyResult<()> {
        tracing::Span::current().record("rev_id", &revision.rev_id);
        self.inner.add(revision.clone(), RevisionState::Ack, true).await
    }

    // Call this method to sync the revisions that already in local db.
    #[tracing::instrument(level = "trace", skip(self), fields(rev_id, object_id=%self.object_id), err)]
    async fn add_sync_revision(&mut self, revision: &Revision) -> FlowyResult<()> {
        tracing::Span::current().record("rev_id", &revision.rev_id);
        self.inner.add(revision.clone(), RevisionState::Sync, false).await?;
        self.sync_seq.add(revision.rev_id)?;
        Ok(())
    }

    // Call this method to save the new revisions generated by the user input.
    #[tracing::instrument(level = "trace", skip(self, revision), fields(rev_id, compact_range, object_id=%self.object_id), err)]
    async fn write_sync_revision<C>(&mut self, revision: &Revision) -> FlowyResult<i64>
    where
        C: RevisionCompact,
    {
        match self.sync_seq.compact() {
            None => {
                tracing::Span::current().record("rev_id", &revision.rev_id);
                self.inner.add(revision.clone(), RevisionState::Sync, true).await?;
                self.sync_seq.add(revision.rev_id)?;
                Ok(revision.rev_id)
            }
            Some((range, mut compact_seq)) => {
                tracing::Span::current().record("compact_range", &format!("{}", range).as_str());
                let mut revisions = self.inner.revisions_in_range(&range).await?;
                if range.to_rev_ids().len() != revisions.len() {
                    debug_assert_eq!(range.to_rev_ids().len(), revisions.len());
                }

                // append the new revision
                revisions.push(revision.clone());

                // compact multiple revisions into one
                let compact_revision = C::compact_revisions(&self.user_id, &self.object_id, revisions)?;
                let rev_id = compact_revision.rev_id;
                tracing::Span::current().record("rev_id", &rev_id);

                // insert new revision
                compact_seq.push_back(rev_id);

                // replace the revisions in range with compact revision
                self.inner.compact(&range, compact_revision).await?;
                debug_assert_eq!(self.sync_seq.len(), compact_seq.len());
                self.sync_seq.reset(compact_seq);
                Ok(rev_id)
            }
        }
    }

    async fn ack_revision(&mut self, rev_id: i64) -> FlowyResult<()> {
        if self.sync_seq.ack(&rev_id).is_ok() {
            self.inner.ack(rev_id).await;
        }
        Ok(())
    }

    async fn next_sync_revision(&self) -> FlowyResult<Option<Revision>> {
        if cfg!(feature = "flowy_unit_test") {
            match self.sync_seq.next_rev_id() {
                None => Ok(None),
                Some(rev_id) => Ok(self.inner.get(rev_id).await.map(|record| record.revision)),
            }
        } else {
            Ok(None)
        }
    }

    async fn reset(&self, revisions: Vec<Revision>) -> FlowyResult<()> {
        self.inner.reset_with_revisions(&self.object_id, revisions).await?;
        Ok(())
    }
}

impl std::ops::Deref for RevisionCompressor {
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

    fn add(&mut self, new_rev_id: i64) -> FlowyResult<()> {
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

    fn reset(&mut self, new_seq: VecDeque<i64>) {
        self.0 = new_seq;
    }

    fn len(&self) -> usize {
        self.0.len()
    }

    // Compact the rev_ids into one except the current synchronizing rev_id.
    fn compact(&self) -> Option<(RevisionRange, VecDeque<i64>)> {
        self.next_rev_id()?;

        let mut new_seq = self.0.clone();
        let mut drained = new_seq.drain(1..).collect::<VecDeque<_>>();

        let start = drained.pop_front()?;
        let end = drained.pop_back().unwrap_or(start);
        Some((RevisionRange { start, end }, new_seq))
    }
}

struct RevisionLoader {
    object_id: String,
    user_id: String,
    cloud: Arc<dyn RevisionCloudService>,
    rev_compressor: Arc<RwLock<RevisionCompressor>>,
}

impl RevisionLoader {
    async fn load<C>(&self) -> Result<(Vec<Revision>, i64), FlowyError>
    where
        C: RevisionCompact,
    {
        let records = self.rev_compressor.read().await.batch_get(&self.object_id)?;
        let revisions: Vec<Revision>;
        let mut rev_id = 0;
        if records.is_empty() {
            let remote_revisions = self.cloud.fetch_object(&self.user_id, &self.object_id).await?;
            for revision in &remote_revisions {
                rev_id = revision.rev_id;
                let _ = self.rev_compressor.read().await.add_ack_revision(revision).await?;
            }
            revisions = remote_revisions;
        } else {
            for record in &records {
                rev_id = record.revision.rev_id;
                if record.state == RevisionState::Sync {
                    // Sync the records if their state is RevisionState::Sync.
                    let _ = self
                        .rev_compressor
                        .write()
                        .await
                        .add_sync_revision(&record.revision)
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
