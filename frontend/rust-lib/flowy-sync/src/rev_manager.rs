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

pub struct RevisionManager {
    pub object_id: String,
    user_id: String,
    rev_id_counter: RevIdCounter,
    revision_cache: Arc<RevisionCache>,
    sync_seq: Arc<RevisionSyncSequence>,

    #[cfg(feature = "flowy_unit_test")]
    revision_ack_notifier: tokio::sync::broadcast::Sender<i64>,
}

impl RevisionManager {
    pub fn new(user_id: &str, object_id: &str, revision_cache: Arc<RevisionCache>) -> Self {
        let rev_id_counter = RevIdCounter::new(0);
        let sync_seq = Arc::new(RevisionSyncSequence::new());
        #[cfg(feature = "flowy_unit_test")]
        let (revision_ack_notifier, _) = tokio::sync::broadcast::channel(1);

        Self {
            object_id: object_id.to_string(),
            user_id: user_id.to_owned(),
            rev_id_counter,
            revision_cache,
            sync_seq,

            #[cfg(feature = "flowy_unit_test")]
            revision_ack_notifier,
        }
    }

    pub async fn load<Builder>(&mut self, cloud: Arc<dyn RevisionCloudService>) -> FlowyResult<Builder::Output>
    where
        Builder: RevisionObjectBuilder,
    {
        let (revisions, rev_id) = RevisionLoader {
            object_id: self.object_id.clone(),
            user_id: self.user_id.clone(),
            cloud,
            revision_cache: self.revision_cache.clone(),
            revision_sync_seq: self.sync_seq.clone(),
        }
        .load()
        .await?;
        self.rev_id_counter.set(rev_id);
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

        self.sync_seq.add_record(revision.rev_id).await?;
        self.revision_cache
            .add(revision.clone(), RevisionState::Sync, true)
            .await?;

        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub async fn ack_revision(&self, rev_id: i64) -> Result<(), FlowyError> {
        if self.sync_seq.ack(&rev_id).await.is_ok() {
            self.revision_cache.ack(rev_id).await;

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
        debug_assert!(range.object_id == self.object_id);
        let revisions = self.revision_cache.revisions_in_range(range.clone()).await?;
        Ok(revisions)
    }

    pub fn next_sync_revision(&self) -> FutureResult<Option<Revision>, FlowyError> {
        let sync_seq = self.sync_seq.clone();
        let revision_cache = self.revision_cache.clone();
        FutureResult::new(async move {
            match sync_seq.next_rev_id().await {
                None => Ok(None),
                Some(rev_id) => Ok(revision_cache.get(rev_id).await.map(|record| record.revision)),
            }
        })
    }

    pub async fn get_revision(&self, rev_id: i64) -> Option<Revision> {
        self.revision_cache.get(rev_id).await.map(|record| record.revision)
    }
}

struct RevisionSyncSequence(Arc<RwLock<VecDeque<i64>>>);
impl std::default::Default for RevisionSyncSequence {
    fn default() -> Self {
        RevisionSyncSequence(Arc::new(RwLock::new(VecDeque::new())))
    }
}

impl RevisionSyncSequence {
    fn new() -> Self {
        RevisionSyncSequence::default()
    }

    async fn add_record(&self, new_rev_id: i64) -> FlowyResult<()> {
        // The last revision's rev_id must be greater than the new one.
        if let Some(rev_id) = self.0.read().await.back() {
            if *rev_id >= new_rev_id {
                return Err(
                    FlowyError::internal().context(format!("The new revision's id must be greater than {}", rev_id))
                );
            }
        }
        self.0.write().await.push_back(new_rev_id);
        Ok(())
    }

    async fn ack(&self, rev_id: &i64) -> FlowyResult<()> {
        let cur_rev_id = self.0.read().await.front().cloned();
        if let Some(pop_rev_id) = cur_rev_id {
            if &pop_rev_id != rev_id {
                let desc = format!(
                    "The ack rev_id:{} is not equal to the current rev_id:{}",
                    rev_id, pop_rev_id
                );
                return Err(FlowyError::internal().context(desc));
            }
            let _ = self.0.write().await.pop_front();
        }
        Ok(())
    }

    async fn next_rev_id(&self) -> Option<i64> {
        self.0.read().await.front().cloned()
    }
}

struct RevisionLoader {
    object_id: String,
    user_id: String,
    cloud: Arc<dyn RevisionCloudService>,
    revision_cache: Arc<RevisionCache>,
    revision_sync_seq: Arc<RevisionSyncSequence>,
}

impl RevisionLoader {
    async fn load(&self) -> Result<(Vec<Revision>, i64), FlowyError> {
        let records = self.revision_cache.batch_get(&self.object_id)?;
        let revisions: Vec<Revision>;
        let mut rev_id = 0;
        if records.is_empty() {
            let remote_revisions = self.cloud.fetch_object(&self.user_id, &self.object_id).await?;
            for revision in &remote_revisions {
                rev_id = revision.rev_id;
                let _ = self
                    .revision_cache
                    .add(revision.clone(), RevisionState::Ack, true)
                    .await?;
            }
            revisions = remote_revisions;
        } else {
            for record in records.clone() {
                let f = || async {
                    rev_id = record.revision.rev_id;
                    if record.state == RevisionState::Sync {
                        // Sync the records if their state is RevisionState::Sync.
                        let _ = self.revision_sync_seq.add_record(record.revision.rev_id).await?;
                        let _ = self.revision_cache.add(record.revision, record.state, false).await?;
                    }
                    Ok::<(), FlowyError>(())
                };
                match f().await {
                    Ok(_) => {}
                    Err(e) => tracing::error!("[RevisionLoader]: {}", e),
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

#[cfg(feature = "flowy_unit_test")]
impl RevisionManager {
    pub fn revision_cache(&self) -> Arc<RevisionCache> {
        self.revision_cache.clone()
    }
    pub fn revision_ack_receiver(&self) -> tokio::sync::broadcast::Receiver<i64> {
        self.revision_ack_notifier.subscribe()
    }
}
