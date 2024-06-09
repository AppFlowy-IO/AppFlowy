use collab::preclude::Collab;
use collab_integrate::{CollabKVAction, PersistenceError};
use std::collections::HashMap;
use tracing::instrument;

#[instrument(level = "debug", skip_all)]
pub fn load_collab_by_oid<'a, R>(
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
    let collab = Collab::new(uid, object_id, "phantom", vec![], false);
    match collab
      .with_origin_transact_mut(|txn| collab_read_txn.load_doc_with_txn(uid, &object_id, txn))
    {
      Ok(_) => {
        collab_by_oid.insert(object_id.clone(), collab);
      },
      Err(err) => tracing::error!("🔴import collab:{} failed: {:?} ", object_id, err),
    }
  }

  collab_by_oid
}
