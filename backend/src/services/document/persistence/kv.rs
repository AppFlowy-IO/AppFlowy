use crate::{services::kv_store::KVStore, util::serde_ext::parse_from_bytes};
use backend_service::errors::ServerError;
use bytes::Bytes;
use lib_ot::protobuf::{RepeatedRevision, Revision};
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

    pub(crate) async fn set_revision(&self, revision: Revision) -> Result<(), ServerError> {
        let key = revision.rev_id.to_string();
        let bytes = revision.write_to_bytes()?;
        let _ = self.inner.set(&key, Bytes::from(bytes)).await?;
        Ok(())
    }

    pub(crate) async fn batch_get_revisions(&self, rev_ids: Vec<i64>) -> Result<RepeatedRevision, ServerError> {
        let keys = rev_ids
            .into_iter()
            .map(|rev_id| rev_id.to_string())
            .collect::<Vec<String>>();

        let items = self.inner.batch_get(keys).await?;
        let revisions = items
            .into_iter()
            .filter_map(|kv| parse_from_bytes::<Revision>(&kv.value).ok())
            .collect::<Vec<Revision>>();

        let mut repeated_revision = RepeatedRevision::new();
        repeated_revision.set_items(revisions.into());
        Ok(repeated_revision)
    }
}
