use collab::preclude::Collab;
use collab_integrate::{CollabKVAction, PersistenceError};
use std::collections::HashMap;
use tracing::instrument;

/// This function loads collab objects by their object_ids.
#[instrument(level = "debug", skip_all)]
pub fn load_collab_by_object_ids<'a, R>(
  uid: i64,
  collab_read_txn: &R,
  object_ids: &[String],
) -> HashMap<String, Collab>
where
  R: CollabKVAction<'a>,
  PersistenceError: From<R::Error>,
{
  let mut collab_by_oid = HashMap::new();

  for object_id in object_ids {
    match load_collab_by_object_id(uid, collab_read_txn, object_id) {
      Ok(collab) => {
        collab_by_oid.insert(object_id.clone(), collab);
      },
      Err(err) => tracing::error!("🔴load collab: {} failed: {:?} ", object_id, err),
    }
  }

  collab_by_oid
}

/// This function loads single collab object by its object_id.
#[instrument(level = "debug", skip_all)]
pub fn load_collab_by_object_id<'a, R>(
  uid: i64,
  collab_read_txn: &R,
  object_id: &str,
) -> Result<Collab, PersistenceError>
where
  R: CollabKVAction<'a>,
  PersistenceError: From<R::Error>,
{
  let collab = Collab::new(uid, object_id, "phantom", vec![], false);
  collab
    .with_origin_transact_mut(|txn| collab_read_txn.load_doc_with_txn(uid, object_id, txn))
    .map(|_| collab)
}
