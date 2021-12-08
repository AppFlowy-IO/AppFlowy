use crate::{
    errors::OTError,
    revision::{Revision, RevisionRange},
};
use dashmap::{mapref::one::RefMut, DashMap};
use std::{collections::VecDeque, fmt::Debug, sync::Arc};
use tokio::sync::{broadcast, RwLock};

pub trait RevisionDiskCache: Sync + Send {
    type Error: Debug;
    fn create_revisions(&self, revisions: Vec<RevisionRecord>) -> Result<(), Self::Error>;
    fn revisions_in_range(&self, doc_id: &str, range: &RevisionRange) -> Result<Vec<Revision>, Self::Error>;
    fn read_revision(&self, doc_id: &str, rev_id: i64) -> Result<Option<Revision>, Self::Error>;
    fn read_revisions(&self, doc_id: &str) -> Result<Vec<Revision>, Self::Error>;
}

pub struct RevisionMemoryCache {
    revs_map: Arc<DashMap<i64, RevisionRecord>>,
    pending_revs: Arc<RwLock<VecDeque<i64>>>,
}

impl std::default::Default for RevisionMemoryCache {
    fn default() -> Self {
        let pending_revs = Arc::new(RwLock::new(VecDeque::new()));
        RevisionMemoryCache {
            revs_map: Arc::new(DashMap::new()),
            pending_revs,
        }
    }
}

impl RevisionMemoryCache {
    pub fn new() -> Self { RevisionMemoryCache::default() }

    pub async fn add_revision(&self, revision: Revision) -> Result<(), OTError> {
        // The last revision's rev_id must be greater than the new one.
        if let Some(rev_id) = self.pending_revs.read().await.back() {
            if *rev_id >= revision.rev_id {
                return Err(OTError::revision_id_conflict()
                    .context(format!("The new revision's id must be greater than {}", rev_id)));
            }
        }

        self.pending_revs.write().await.push_back(revision.rev_id);
        self.revs_map.insert(revision.rev_id, RevisionRecord::new(revision));
        Ok(())
    }

    pub fn remove_revisions(&self, ids: Vec<i64>) { self.revs_map.retain(|k, _| !ids.contains(k)); }

    pub fn mut_revision<F>(&self, rev_id: &i64, f: F)
    where
        F: Fn(RefMut<i64, RevisionRecord>),
    {
        if let Some(m_revision) = self.revs_map.get_mut(rev_id) {
            f(m_revision)
        } else {
            log::error!("Can't find revision with id {}", rev_id);
        }
    }

    pub async fn revisions_in_range(&self, range: &RevisionRange) -> Result<Vec<Revision>, OTError> {
        let revs = range
            .iter()
            .flat_map(|rev_id| match self.revs_map.get(&rev_id) {
                None => None,
                Some(rev) => Some(rev.revision.clone()),
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

    pub async fn front_revision(&self) -> Option<(i64, RevisionRecord)> {
        match self.pending_revs.read().await.front() {
            None => None,
            Some(rev_id) => self.revs_map.get(rev_id).map(|r| (*r.key(), r.value().clone())),
        }
    }

    pub async fn front_rev_id(&self) -> Option<i64> { self.pending_revs.read().await.front().copied() }
}

pub type RevIdReceiver = broadcast::Receiver<i64>;
pub type RevIdSender = broadcast::Sender<i64>;

#[derive(Clone, Eq, PartialEq)]
pub enum RevState {
    Local = 0,
    Acked = 1,
}

#[derive(Clone)]
pub struct RevisionRecord {
    pub revision: Revision,
    pub state: RevState,
}

impl RevisionRecord {
    pub fn new(revision: Revision) -> Self {
        Self {
            revision,
            state: RevState::Local,
        }
    }

    pub fn ack(&mut self) { self.state = RevState::Acked; }
}

#[cfg(feature = "flowy_unit_test")]
impl RevisionMemoryCache {
    pub fn revs_map(&self) -> Arc<DashMap<i64, RevisionRecord>> { self.revs_map.clone() }
    pub fn pending_revs(&self) -> Arc<RwLock<VecDeque<i64>>> { self.pending_revs.clone() }
}
