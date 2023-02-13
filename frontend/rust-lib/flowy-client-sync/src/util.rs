use crate::errors::SyncError;
use dissimilar::Chunk;
use document_model::document::DocumentInfo;
use lib_ot::core::{DeltaOperationBuilder, OTString, OperationAttributes};
use lib_ot::{
  core::{DeltaOperations, OperationTransform, NEW_LINE, WHITESPACE},
  text_delta::DeltaTextOperations,
};
use revision_model::Revision;
use serde::de::DeserializeOwned;

#[inline]
pub fn find_newline(s: &str) -> Option<usize> {
  s.find(NEW_LINE)
}

#[inline]
pub fn is_newline(s: &str) -> bool {
  s == NEW_LINE
}

#[inline]
pub fn is_whitespace(s: &str) -> bool {
  s == WHITESPACE
}

#[inline]
pub fn contain_newline(s: &str) -> bool {
  s.contains(NEW_LINE)
}

pub fn recover_operation_from_revisions<T>(
  revisions: Vec<Revision>,
  validator: impl Fn(&DeltaOperations<T>) -> bool,
) -> Option<(DeltaOperations<T>, i64)>
where
  T: OperationAttributes + DeserializeOwned + OperationAttributes,
{
  let mut new_operations = DeltaOperations::<T>::new();
  let mut rev_id = 0;
  for revision in revisions {
    if let Ok(operations) = DeltaOperations::<T>::from_bytes(revision.bytes) {
      match new_operations.compose(&operations) {
        Ok(composed_operations) => {
          if validator(&composed_operations) {
            rev_id = revision.rev_id;
            new_operations = composed_operations;
          } else {
            break;
          }
        },
        Err(_) => break,
      }
    } else {
      break;
    }
  }
  if new_operations.is_empty() {
    None
  } else {
    Some((new_operations, rev_id))
  }
}

#[inline]
pub fn make_document_info_from_revisions(
  doc_id: &str,
  revisions: Vec<Revision>,
) -> Result<Option<DocumentInfo>, SyncError> {
  if revisions.is_empty() {
    return Ok(None);
  }

  let mut delta = DeltaTextOperations::new();
  let mut base_rev_id = 0;
  let mut rev_id = 0;
  for revision in revisions {
    base_rev_id = revision.base_rev_id;
    rev_id = revision.rev_id;

    if revision.bytes.is_empty() {
      tracing::warn!("revision delta_data is empty");
    }

    let new_delta = DeltaTextOperations::from_bytes(revision.bytes)?;
    delta = delta.compose(&new_delta)?;
  }

  Ok(Some(DocumentInfo {
    doc_id: doc_id.to_owned(),
    data: delta.json_bytes().to_vec(),
    rev_id,
    base_rev_id,
  }))
}

#[inline]
pub fn rev_id_from_str(s: &str) -> Result<i64, SyncError> {
  let rev_id = s
    .to_owned()
    .parse::<i64>()
    .map_err(|e| SyncError::internal().context(format!("Parse rev_id from {} failed. {}", s, e)))?;
  Ok(rev_id)
}

pub fn cal_diff<T: OperationAttributes>(old: String, new: String) -> Option<DeltaOperations<T>> {
  let chunks = dissimilar::diff(&old, &new);
  let mut delta_builder = DeltaOperationBuilder::<T>::new();
  for chunk in &chunks {
    match chunk {
      Chunk::Equal(s) => {
        delta_builder = delta_builder.retain(OTString::from(*s).utf16_len());
      },
      Chunk::Delete(s) => {
        delta_builder = delta_builder.delete(OTString::from(*s).utf16_len());
      },
      Chunk::Insert(s) => {
        delta_builder = delta_builder.insert(s);
      },
    }
  }

  let delta = delta_builder.build();
  if delta.is_empty() {
    None
  } else {
    Some(delta)
  }
}
