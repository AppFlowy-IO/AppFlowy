use crate::errors::{SyncError, SyncResult};

use lib_ot::core::{DeltaOperations, OperationAttributes, OperationTransform};
use revision_model::Revision;
use serde::de::DeserializeOwned;

pub fn pair_rev_id_from_revision_pbs(revisions: &[Revision]) -> (i64, i64) {
  let mut rev_id = 0;
  revisions.iter().for_each(|revision| {
    if rev_id < revision.rev_id {
      rev_id = revision.rev_id;
    }
  });

  if rev_id > 0 {
    (rev_id - 1, rev_id)
  } else {
    (0, rev_id)
  }
}

#[tracing::instrument(level = "trace", skip(revisions), err)]
pub fn make_operations_from_revisions<T>(revisions: Vec<Revision>) -> SyncResult<DeltaOperations<T>>
where
  T: OperationAttributes + DeserializeOwned + OperationAttributes + serde::Serialize,
{
  let mut new_operations = DeltaOperations::<T>::new();
  for revision in revisions {
    if revision.bytes.is_empty() {
      return Err(SyncError::unexpected_empty_revision().context("Unexpected Empty revision"));
    }
    let operations = DeltaOperations::<T>::from_bytes(revision.bytes).map_err(|e| {
      let err_msg = format!("Deserialize revision failed: {:?}", e);
      SyncError::internal().context(err_msg)
    })?;

    new_operations = new_operations.compose(&operations)?;
  }
  Ok(new_operations)
}

#[inline]
pub fn next(rev_id: i64) -> i64 {
  rev_id + 1
}
