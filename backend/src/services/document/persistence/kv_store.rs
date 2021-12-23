use crate::{services::kv::KVStore, util::serde_ext::parse_from_bytes};
use backend_service::errors::ServerError;
use bytes::Bytes;
use flowy_collaboration::protobuf::{RepeatedRevision, Revision};
use futures::stream::{self, StreamExt};
use protobuf::Message;
use std::sync::Arc;

pub struct DocumentKVPersistence {
    inner: Arc<dyn KVStore>,
}

impl std::ops::Deref for DocumentKVPersistence {
    type Target = Arc<dyn KVStore>;

    fn deref(&self) -> &Self::Target { &self.inner }
}

impl std::ops::DerefMut for DocumentKVPersistence {
    fn deref_mut(&mut self) -> &mut Self::Target { &mut self.inner }
}

impl DocumentKVPersistence {
    pub(crate) fn new(kv_store: Arc<dyn KVStore>) -> Self { DocumentKVPersistence { inner: kv_store } }

    pub(crate) async fn batch_set_revision(&self, revisions: Vec<Revision>) -> Result<(), ServerError> {
        let kv_store = self.inner.clone();

        let f = |revision: Revision, kv_store: Arc<dyn KVStore>| async move {
            let key = make_revision_key(&revision.doc_id, revision.rev_id);
            let bytes = revision.write_to_bytes().unwrap();
            let _ = kv_store.set(&key, Bytes::from(bytes)).await;
        };

        stream::iter(revisions)
            .for_each_concurrent(None, |revision| f(revision, kv_store.clone()))
            .await;
        Ok(())
    }

    pub(crate) async fn batch_get_revisions<T: Into<Option<Vec<i64>>>>(
        &self,
        doc_id: &str,
        rev_ids: T,
    ) -> Result<RepeatedRevision, ServerError> {
        let rev_ids = rev_ids.into();
        let items = match rev_ids {
            None => self.inner.batch_get_key_start_with(doc_id).await?,
            Some(rev_ids) => {
                let keys = rev_ids
                    .into_iter()
                    .map(|rev_id| make_revision_key(doc_id, rev_id))
                    .collect::<Vec<String>>();
                self.inner.batch_get(keys).await?
            },
        };

        let revisions = items
            .into_iter()
            .filter_map(|kv| parse_from_bytes::<Revision>(&kv.value).ok())
            .collect::<Vec<Revision>>();

        let mut repeated_revision = RepeatedRevision::new();
        repeated_revision.set_items(revisions.into());
        Ok(repeated_revision)
    }

    pub(crate) async fn batch_delete_revisions<T: Into<Option<Vec<i64>>>>(
        &self,
        doc_id: &str,
        rev_ids: T,
    ) -> Result<(), ServerError> {
        match rev_ids.into() {
            None => {
                let _ = self.inner.batch_delete_key_start_with(doc_id).await?;
                Ok(())
            },
            Some(rev_ids) => {
                let keys = rev_ids
                    .into_iter()
                    .map(|rev_id| make_revision_key(doc_id, rev_id))
                    .collect::<Vec<String>>();
                let _ = self.inner.batch_delete(keys).await?;
                Ok(())
            },
        }
    }
}

#[inline]
fn make_revision_key(doc_id: &str, rev_id: i64) -> String { format!("{}:{}", doc_id, rev_id) }
