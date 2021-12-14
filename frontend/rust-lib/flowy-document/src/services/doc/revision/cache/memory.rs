use crate::services::doc::revision::RevisionRecord;
use dashmap::DashMap;
use lib_ot::{
    errors::OTError,
    revision::{RevState, Revision, RevisionRange},
};
use std::{collections::VecDeque, sync::Arc};
use tokio::sync::RwLock;

pub struct RevisionMemoryCache {
    revs_map: Arc<DashMap<i64, RevisionRecord>>,
    local_revs: Arc<RwLock<VecDeque<i64>>>,
}

impl std::default::Default for RevisionMemoryCache {
    fn default() -> Self {
        let local_revs = Arc::new(RwLock::new(VecDeque::new()));
        RevisionMemoryCache {
            revs_map: Arc::new(DashMap::new()),
            local_revs,
        }
    }
}

impl RevisionMemoryCache {
    pub fn new() -> Self { RevisionMemoryCache::default() }

    pub async fn add_revision(&self, record: RevisionRecord) -> Result<(), OTError> {
        // The last revision's rev_id must be greater than the new one.
        if let Some(rev_id) = self.local_revs.read().await.back() {
            if *rev_id >= record.revision.rev_id {
                return Err(OTError::revision_id_conflict()
                    .context(format!("The new revision's id must be greater than {}", rev_id)));
            }
        }

        match record.state {
            RevState::StateLocal => {
                tracing::debug!("{}:add revision {}", record.revision.doc_id, record.revision.rev_id);
                self.local_revs.write().await.push_back(record.revision.rev_id);
            },
            RevState::Acked => {},
        }

        self.revs_map.insert(record.revision.rev_id, record);
        Ok(())
    }

    pub fn remove_revisions(&self, ids: Vec<i64>) { self.revs_map.retain(|k, _| !ids.contains(k)); }

    pub async fn ack_revision(&self, rev_id: &i64) {
        if let Some(pop_rev_id) = self.front_local_rev_id().await {
            if &pop_rev_id != rev_id {
                return;
            }
        }

        match self.local_revs.write().await.pop_front() {
            None => tracing::error!("❌The local_revs should not be empty"),
            Some(pop_rev_id) => {
                if &pop_rev_id != rev_id {
                    tracing::error!("The front rev_id:{} not equal to ack rev_id: {}", pop_rev_id, rev_id);
                    assert_eq!(&pop_rev_id, rev_id);
                } else {
                    tracing::debug!("pop revision {}", pop_rev_id);
                }
            },
        }
    }

    pub async fn revisions_in_range(&self, range: &RevisionRange) -> Result<Vec<Revision>, OTError> {
        let revs = range
            .iter()
            .flat_map(|rev_id| match self.revs_map.get(&rev_id) {
                None => None,
                Some(record) => Some(record.revision.clone()),
            })
            .collect::<Vec<Revision>>();

        if revs.len() == range.len() as usize {
            Ok(revs)
        } else {
            Ok(vec![])
        }
    }

    pub fn contains(&self, rev_id: &i64) -> bool { self.revs_map.contains_key(rev_id) }

    pub fn is_empty(&self) -> bool { self.revs_map.is_empty() }

    pub fn revisions(&self) -> (Vec<i64>, Vec<RevisionRecord>) {
        let mut records: Vec<RevisionRecord> = vec![];
        let mut ids: Vec<i64> = vec![];

        self.revs_map.iter().for_each(|kv| {
            records.push(kv.value().clone());
            ids.push(*kv.key());
        });
        (ids, records)
    }

    pub async fn query_revision(&self, rev_id: &i64) -> Option<RevisionRecord> {
        self.revs_map.get(&rev_id).map(|r| r.value().clone())
    }

    pub async fn front_local_revision(&self) -> Option<(i64, RevisionRecord)> {
        match self.local_revs.read().await.front() {
            None => None,
            Some(rev_id) => match self.revs_map.get(rev_id).map(|r| (*r.key(), r.value().clone())) {
                None => None,
                Some(val) => {
                    tracing::debug!("{}:try send revision {}", val.1.revision.doc_id, val.1.revision.rev_id);
                    Some(val)
                },
            },
        }
    }

    pub async fn front_local_rev_id(&self) -> Option<i64> { self.local_revs.read().await.front().copied() }
}

#[cfg(feature = "flowy_unit_test")]
impl RevisionMemoryCache {
    pub fn revs_map(&self) -> Arc<DashMap<i64, RevisionRecord>> { self.revs_map.clone() }
    pub fn pending_revs(&self) -> Arc<RwLock<VecDeque<i64>>> { self.local_revs.clone() }
}
