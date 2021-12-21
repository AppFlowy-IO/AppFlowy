use crate::services::doc::revision::RevisionRecord;
use dashmap::DashMap;
use flowy_error::{FlowyError, FlowyResult};
use lib_ot::errors::OTError;
use std::{collections::VecDeque, sync::Arc};
use tokio::sync::RwLock;

pub struct RevisionSyncSeq {
    revs_map: Arc<DashMap<i64, RevisionRecord>>,
    local_revs: Arc<RwLock<VecDeque<i64>>>,
}

impl std::default::Default for RevisionSyncSeq {
    fn default() -> Self {
        let local_revs = Arc::new(RwLock::new(VecDeque::new()));
        RevisionSyncSeq {
            revs_map: Arc::new(DashMap::new()),
            local_revs,
        }
    }
}

impl RevisionSyncSeq {
    pub fn new() -> Self { RevisionSyncSeq::default() }

    pub async fn add_revision(&self, record: RevisionRecord) -> Result<(), OTError> {
        // The last revision's rev_id must be greater than the new one.
        if let Some(rev_id) = self.local_revs.read().await.back() {
            if *rev_id >= record.revision.rev_id {
                return Err(OTError::revision_id_conflict()
                    .context(format!("The new revision's id must be greater than {}", rev_id)));
            }
        }
        self.local_revs.write().await.push_back(record.revision.rev_id);
        self.revs_map.insert(record.revision.rev_id, record);
        Ok(())
    }

    pub async fn ack_revision(&self, rev_id: &i64) -> FlowyResult<()> {
        if let Some(pop_rev_id) = self.next_sync_rev_id().await {
            if &pop_rev_id != rev_id {
                let desc = format!(
                    "The ack rev_id:{} is not equal to the current rev_id:{}",
                    rev_id, pop_rev_id
                );
                // tracing::error!("{}", desc);
                return Err(FlowyError::internal().context(desc));
            }

            tracing::debug!("pop revision {}", pop_rev_id);
            self.revs_map.remove(&pop_rev_id);
            let _ = self.local_revs.write().await.pop_front();
        }
        Ok(())
    }

    pub async fn next_sync_revision(&self) -> Option<(i64, RevisionRecord)> {
        match self.local_revs.read().await.front() {
            None => None,
            Some(rev_id) => self.revs_map.get(rev_id).map(|r| (*r.key(), r.value().clone())),
        }
    }

    pub async fn next_sync_rev_id(&self) -> Option<i64> { self.local_revs.read().await.front().copied() }
}

#[cfg(feature = "flowy_unit_test")]
impl RevisionSyncSeq {
    pub fn revs_map(&self) -> Arc<DashMap<i64, RevisionRecord>> { self.revs_map.clone() }
    pub fn pending_revs(&self) -> Arc<RwLock<VecDeque<i64>>> { self.local_revs.clone() }
}
