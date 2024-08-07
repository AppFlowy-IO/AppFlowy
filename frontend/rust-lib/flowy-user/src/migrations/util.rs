use collab::preclude::Collab;

use collab_integrate::{CollabKVAction, PersistenceError};
use flowy_error::FlowyResult;

pub(crate) fn load_collab<'a, R>(uid: i64, collab_r_txn: &R, object_id: &str) -> FlowyResult<Collab>
where
  R: CollabKVAction<'a>,
  PersistenceError: From<R::Error>,
{
  let mut collab = Collab::new(uid, object_id, "phantom", vec![], false);
  collab_r_txn.load_doc_with_txn(uid, &object_id, &mut collab.transact_mut())?;
  Ok(collab)
}
