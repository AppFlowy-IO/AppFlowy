use std::sync::Arc;

use collab::core::collab::MutexCollab;
use collab::preclude::Collab;

use collab_integrate::{PersistenceError, YrsDocAction};
use flowy_error::{internal_error, FlowyResult};

pub fn load_collab<'a, R>(
  uid: i64,
  collab_r_txn: &R,
  object_id: &str,
) -> FlowyResult<Arc<MutexCollab>>
where
  R: YrsDocAction<'a>,
  PersistenceError: From<R::Error>,
{
  let collab = Collab::new(uid, object_id, "phantom", vec![]);
  collab
    .with_origin_transact_mut(|txn| collab_r_txn.load_doc_with_txn(uid, &object_id, txn))
    .map_err(internal_error)?;
  Ok(Arc::new(MutexCollab::from_collab(collab)))
}
