use crate::services::doc::RevisionRecord;
use dashmap::DashMap;
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;
use lib_ot::revision::RevisionRange;
use std::sync::Arc;
use tokio::sync::RwLock;

pub(crate) trait RevisionMemoryCacheMissing: Send + Sync {
    fn get_revision_record(&self, doc_id: &str, rev_id: i64) -> Result<Option<RevisionRecord>, FlowyError>;
    fn get_revision_records_with_range(
        &self,
        doc_id: &str,
        range: RevisionRange,
    ) -> FutureResult<Vec<RevisionRecord>, FlowyError>;
}

pub(crate) struct RevisionMemoryCache {
    doc_id: String,
    revs_map: Arc<DashMap<i64, RevisionRecord>>,
    rev_loader: Arc<dyn RevisionMemoryCacheMissing>,
    revs_order: Arc<RwLock<Vec<i64>>>,
}

// TODO: remove outdated revisions to reduce memory usage
impl RevisionMemoryCache {
    pub(crate) fn new(doc_id: &str, rev_loader: Arc<dyn RevisionMemoryCacheMissing>) -> Self {
        RevisionMemoryCache {
            doc_id: doc_id.to_owned(),
            revs_map: Arc::new(DashMap::new()),
            rev_loader,
            revs_order: Arc::new(RwLock::new(vec![])),
        }
    }

    pub(crate) async fn is_empty(&self) -> bool { self.revs_order.read().await.is_empty() }

    pub(crate) fn contains(&self, rev_id: &i64) -> bool { self.revs_map.contains_key(rev_id) }

    pub(crate) async fn add_revision(&self, record: &RevisionRecord) {
        if let Some(rev_id) = self.revs_order.read().await.last() {
            if *rev_id >= record.revision.rev_id {
                tracing::error!("Duplicated revision added to memory_cache");
                return;
            }
        }
        self.revs_map.insert(record.revision.rev_id, record.clone());
        self.revs_order.write().await.push(record.revision.rev_id);
    }

    pub(crate) async fn get_revision(&self, rev_id: &i64) -> Option<RevisionRecord> {
        match self.revs_map.get(&rev_id).map(|r| r.value().clone()) {
            None => match self.rev_loader.get_revision_record(&self.doc_id, *rev_id) {
                Ok(revision) => revision,
                Err(e) => {
                    tracing::error!("{}", e);
                    None
                },
            },
            Some(revision) => Some(revision),
        }
    }

    pub(crate) async fn get_revisions_in_range(
        &self,
        range: &RevisionRange,
    ) -> Result<Vec<RevisionRecord>, FlowyError> {
        let range_len = range.len() as usize;
        let revs = range
            .iter()
            .flat_map(|rev_id| self.revs_map.get(&rev_id).map(|record| record.clone()))
            .collect::<Vec<RevisionRecord>>();

        if revs.len() == range_len {
            Ok(revs)
        } else {
            let revs = self
                .rev_loader
                .get_revision_records_with_range(&self.doc_id, range.clone())
                .await?;
            if revs.len() != range_len {
                log::error!("Revisions len is not equal to range required");
            }
            Ok(revs)
        }
    }
}
