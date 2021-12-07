use crate::{
    errors::OTError,
    revision::{RevId, Revision, RevisionRange},
};
use dashmap::{mapref::one::RefMut, DashMap};
use std::{collections::VecDeque, sync::Arc};
use tokio::sync::{broadcast, RwLock};

pub trait RevisionDiskCache {
    fn create_revision(&self, revision: &Revision) -> Result<(), OTError>;
    fn revisions_in_range(&self, range: RevisionRange) -> Result<Option<Vec<Revision>>, OTError>;
    fn read_revision(&self, rev_id: i64) -> Result<Option<Revision>, OTError>;
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
        if self.revs_map.contains_key(&revision.rev_id) {
            return Err(OTError::duplicate_revision().context(format!("Duplicate revision id: {}", revision.rev_id)));
        }

        self.pending_revs.write().await.push_back(revision.rev_id);
        self.revs_map.insert(revision.rev_id, RevisionRecord::new(revision));
        Ok(())
    }

    pub async fn mut_revision<F>(&self, rev_id: i64, f: F)
    where
        F: Fn(RefMut<i64, RevisionRecord>),
    {
        if let Some(m_revision) = self.revs_map.get_mut(&rev_id) {
            f(m_revision)
        } else {
            log::error!("Can't find revision with id {}", rev_id);
        }
    }

    pub async fn revisions_in_range(&self, range: RevisionRange) -> Result<Option<Vec<Revision>>, OTError> {
        let revs = range
            .iter()
            .flat_map(|rev_id| match self.revs_map.get(&rev_id) {
                None => None,
                Some(rev) => Some(rev.revision.clone()),
            })
            .collect::<Vec<Revision>>();

        if revs.len() == range.len() as usize {
            Ok(Some(revs))
        } else {
            Ok(None)
        }
    }
}

pub type RevIdReceiver = broadcast::Receiver<i64>;
pub type RevIdSender = broadcast::Sender<i64>;

pub enum RevState {
    Local = 0,
    Acked = 1,
}

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
}

pub struct PendingRevId {
    pub rev_id: i64,
    pub sender: RevIdSender,
}

impl PendingRevId {
    pub fn new(rev_id: i64, sender: RevIdSender) -> Self { Self { rev_id, sender } }

    pub fn finish(&self, rev_id: i64) -> bool {
        if self.rev_id > rev_id {
            false
        } else {
            let _ = self.sender.send(self.rev_id);
            true
        }
    }
}
