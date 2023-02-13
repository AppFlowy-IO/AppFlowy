use flowy_sync::errors::SyncError;
use flowy_sync::{RevisionOperations, RevisionSyncObject, RevisionSynchronizer};
use folder_model::FolderInfo;
use lib_ot::core::{DeltaOperationBuilder, DeltaOperations, EmptyAttributes, OperationTransform};
use revision_model::Revision;

pub type FolderRevisionSynchronizer = RevisionSynchronizer<EmptyAttributes>;
pub type FolderOperations = DeltaOperations<EmptyAttributes>;
pub type FolderOperationsBuilder = DeltaOperationBuilder<EmptyAttributes>;

pub struct ServerFolder {
  folder_id: String,
  operations: FolderOperations,
}

impl ServerFolder {
  pub fn from_operations(folder_id: &str, operations: FolderOperations) -> Self {
    Self {
      folder_id: folder_id.to_owned(),
      operations,
    }
  }
}

impl RevisionSyncObject<EmptyAttributes> for ServerFolder {
  fn object_id(&self) -> &str {
    &self.folder_id
  }

  fn object_json(&self) -> String {
    self.operations.json_str()
  }

  fn compose(&mut self, other: &FolderOperations) -> Result<(), SyncError> {
    let operations = self.operations.compose(other)?;
    self.operations = operations;
    Ok(())
  }

  fn transform(
    &self,
    other: &FolderOperations,
  ) -> Result<(FolderOperations, FolderOperations), SyncError> {
    let value = self.operations.transform(other)?;
    Ok(value)
  }

  fn set_operations(&mut self, operations: RevisionOperations<EmptyAttributes>) {
    self.operations = operations;
  }
}

#[inline]
pub fn make_folder_from_revisions(
  folder_id: &str,
  revisions: Vec<Revision>,
) -> Result<Option<FolderInfo>, SyncError> {
  if revisions.is_empty() {
    return Ok(None);
  }

  let mut folder_delta = FolderOperations::new();
  let mut base_rev_id = 0;
  let mut rev_id = 0;
  for revision in revisions {
    base_rev_id = revision.base_rev_id;
    rev_id = revision.rev_id;
    if revision.bytes.is_empty() {
      tracing::warn!("revision delta_data is empty");
    }
    let delta = FolderOperations::from_bytes(revision.bytes)?;
    folder_delta = folder_delta.compose(&delta)?;
  }

  let text = folder_delta.json_str();
  Ok(Some(FolderInfo {
    folder_id: folder_id.to_string(),
    text,
    rev_id,
    base_rev_id,
  }))
}
