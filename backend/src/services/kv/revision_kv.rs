use crate::{
    services::kv::{KVStore, KeyValue},
    util::serde_ext::parse_from_bytes,
};
use backend_service::errors::ServerError;
use bytes::Bytes;
use flowy_collaboration::protobuf::{RepeatedRevision as RepeatedRevisionPB, Revision as RevisionPB};

use protobuf::Message;
use std::sync::Arc;

pub struct RevisionKVPersistence {
    inner: Arc<KVStore>,
}

impl std::ops::Deref for RevisionKVPersistence {
    type Target = Arc<KVStore>;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl std::ops::DerefMut for RevisionKVPersistence {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.inner
    }
}

impl RevisionKVPersistence {
    pub(crate) fn new(kv_store: Arc<KVStore>) -> Self {
        RevisionKVPersistence { inner: kv_store }
    }

    pub(crate) async fn set_revision(&self, revisions: Vec<RevisionPB>) -> Result<(), ServerError> {
        let items = revisions_to_key_value_items(revisions)?;
        self.inner
            .transaction(|mut t| Box::pin(async move { t.batch_set(items).await }))
            .await
    }

    pub(crate) async fn get_revisions<T: Into<Option<Vec<i64>>>>(
        &self,
        object_id: &str,
        rev_ids: T,
    ) -> Result<RepeatedRevisionPB, ServerError> {
        let rev_ids = rev_ids.into();
        let items = match rev_ids {
            None => {
                let object_id = object_id.to_owned();
                self.inner
                    .transaction(|mut t| Box::pin(async move { t.batch_get_start_with(&object_id).await }))
                    .await?
            }
            Some(rev_ids) => {
                let keys = rev_ids
                    .into_iter()
                    .map(|rev_id| make_revision_key(object_id, rev_id))
                    .collect::<Vec<String>>();

                self.inner
                    .transaction(|mut t| Box::pin(async move { t.batch_get(keys).await }))
                    .await?
            }
        };

        Ok(key_value_items_to_revisions(items))
    }

    pub(crate) async fn delete_revisions<T: Into<Option<Vec<i64>>>>(
        &self,
        object_id: &str,
        rev_ids: T,
    ) -> Result<(), ServerError> {
        match rev_ids.into() {
            None => {
                let object_id = object_id.to_owned();
                self.inner
                    .transaction(|mut t| Box::pin(async move { t.batch_delete_key_start_with(&object_id).await }))
                    .await
            }
            Some(rev_ids) => {
                let keys = rev_ids
                    .into_iter()
                    .map(|rev_id| make_revision_key(object_id, rev_id))
                    .collect::<Vec<String>>();

                self.inner
                    .transaction(|mut t| Box::pin(async move { t.batch_delete(keys).await }))
                    .await
            }
        }
    }
}

#[inline]
pub fn revisions_to_key_value_items(revisions: Vec<RevisionPB>) -> Result<Vec<KeyValue>, ServerError> {
    let mut items = vec![];
    for revision in revisions {
        let key = make_revision_key(&revision.object_id, revision.rev_id);

        if revision.delta_data.is_empty() {
            return Err(ServerError::internal().context("The delta_data of RevisionPB should not be empty"));
        }

        let value = Bytes::from(revision.write_to_bytes().unwrap());
        items.push(KeyValue { key, value });
    }
    Ok(items)
}

#[inline]
fn key_value_items_to_revisions(items: Vec<KeyValue>) -> RepeatedRevisionPB {
    let mut revisions = items
        .into_iter()
        .filter_map(|kv| parse_from_bytes::<RevisionPB>(&kv.value).ok())
        .collect::<Vec<RevisionPB>>();

    revisions.sort_by(|a, b| a.rev_id.cmp(&b.rev_id));
    let mut repeated_revision = RepeatedRevisionPB::new();
    repeated_revision.set_items(revisions.into());
    repeated_revision
}

#[inline]
fn make_revision_key(object_id: &str, rev_id: i64) -> String {
    format!("{}:{}", object_id, rev_id)
}
