use std::sync::Arc;

use collab::core::collab::MutexCollab;
use collab::preclude::Collab;

use collab_integrate::{CollabKVAction, PersistenceError};
use flowy_error::FlowyResult;

pub(crate) fn load_collab<'a, R>(
  uid: i64,
  collab_r_txn: &R,
  object_id: &str,
) -> FlowyResult<Arc<MutexCollab>>
where
  R: CollabKVAction<'a>,
  PersistenceError: From<R::Error>,
{
  let collab = Collab::new(uid, object_id, "phantom", vec![], false);
  collab.with_origin_transact_mut(|txn| collab_r_txn.load_doc_with_txn(uid, &object_id, txn))?;
  Ok(Arc::new(MutexCollab::new(collab)))
}
