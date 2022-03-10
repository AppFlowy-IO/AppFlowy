use crate::disk::RevisionState;
use crate::{RevisionPersistence, WSDataProviderDataSource};
use flowy_collaboration::{
    entities::revision::{RepeatedRevision, Revision, RevisionRange},
    util::{pair_rev_id_from_revisions, RevIdCounter},
};
use flowy_error::{FlowyError, FlowyResult};
use lib_infra::future::FutureResult;
use std::sync::Arc;

pub trait RevisionCloudService: Send + Sync {
    fn fetch_object(&self, user_id: &str, object_id: &str) -> FutureResult<Vec<Revision>, FlowyError>;
}

pub trait RevisionObjectBuilder: Send + Sync {
    type Output;
    fn build_object(object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output>;
}

pub trait RevisionCompact: Send + Sync {
    fn compact_revisions(user_id: &str, object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Revision>;
}

pub struct RevisionManager {
    pub object_id: String,
    user_id: String,
    rev_id_counter: RevIdCounter,
    rev_persistence: Arc<RevisionPersistence>,

    #[cfg(feature = "flowy_unit_test")]
    rev_ack_notifier: tokio::sync::broadcast::Sender<i64>,
}

impl RevisionManager {
    pub fn new(user_id: &str, object_id: &str, rev_persistence: Arc<RevisionPersistence>) -> Self {
        let rev_id_counter = RevIdCounter::new(0);
        #[cfg(feature = "flowy_unit_test")]
        let (revision_ack_notifier, _) = tokio::sync::broadcast::channel(1);

        Self {
            object_id: object_id.to_string(),
            user_id: user_id.to_owned(),
            rev_id_counter,
            rev_persistence,

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
            cloud: Some(cloud),
            rev_persistence: self.rev_persistence.clone(),
        }
        .load()
        .await?;
        self.rev_id_counter.set(rev_id);
        B::build_object(&self.object_id, revisions)
    }

    #[tracing::instrument(level = "debug", skip(self, revisions), err)]
    pub async fn reset_object(&self, revisions: RepeatedRevision) -> FlowyResult<()> {
        let rev_id = pair_rev_id_from_revisions(&revisions).1;
        let _ = self.rev_persistence.reset(revisions.into_inner()).await?;
        self.rev_id_counter.set(rev_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision), err)]
    pub async fn add_remote_revision(&self, revision: &Revision) -> Result<(), FlowyError> {
        if revision.delta_data.is_empty() {
            return Err(FlowyError::internal().context("Delta data should be empty"));
        }

        let _ = self.rev_persistence.add_ack_revision(revision).await?;
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
        let rev_id = self.rev_persistence.add_sync_revision::<C>(revision).await?;
        self.rev_id_counter.set(rev_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub async fn ack_revision(&self, rev_id: i64) -> Result<(), FlowyError> {
        if self.rev_persistence.ack_revision(rev_id).await.is_ok() {
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
        let revisions = self.rev_persistence.revisions_in_range(&range).await?;
        Ok(revisions)
    }

    pub async fn next_sync_revision(&self) -> FlowyResult<Option<Revision>> {
        Ok(self.rev_persistence.next_sync_revision().await?)
    }

    pub async fn get_revision(&self, rev_id: i64) -> Option<Revision> {
        self.rev_persistence.get(rev_id).await.map(|record| record.revision)
    }
}

impl WSDataProviderDataSource for Arc<RevisionManager> {
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
impl RevisionManager {
    pub async fn revision_cache(&self) -> Arc<RevisionPersistence> {
        self.rev_persistence.clone()
    }
    pub fn ack_notify(&self) -> tokio::sync::broadcast::Receiver<i64> {
        self.rev_ack_notifier.subscribe()
    }
}

pub struct RevisionLoader {
    pub object_id: String,
    pub user_id: String,
    pub cloud: Option<Arc<dyn RevisionCloudService>>,
    pub rev_persistence: Arc<RevisionPersistence>,
}

impl RevisionLoader {
    pub async fn load(&self) -> Result<(Vec<Revision>, i64), FlowyError> {
        let records = self.rev_persistence.batch_get(&self.object_id)?;
        let revisions: Vec<Revision>;
        let mut rev_id = 0;
        if records.is_empty() && self.cloud.is_some() {
            let remote_revisions = self
                .cloud
                .as_ref()
                .unwrap()
                .fetch_object(&self.user_id, &self.object_id)
                .await?;
            for revision in &remote_revisions {
                rev_id = revision.rev_id;
                let _ = self.rev_persistence.add_ack_revision(revision).await?;
            }
            revisions = remote_revisions;
        } else {
            for record in &records {
                rev_id = record.revision.rev_id;
                if record.state == RevisionState::Sync {
                    // Sync the records if their state is RevisionState::Sync.
                    let _ = self.rev_persistence.sync_revision(&record.revision).await?;
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
