use flowy_sync::errors::SyncError;
use flowy_sync::{RevisionOperations, RevisionSyncObject};
use lib_ot::{core::*, text_delta::DeltaTextOperations};

pub struct ServerDocument {
  document_id: String,
  operations: DeltaTextOperations,
}

impl ServerDocument {
  pub fn from_operations(document_id: &str, operations: DeltaTextOperations) -> Self {
    let document_id = document_id.to_owned();
    ServerDocument {
      document_id,
      operations,
    }
  }
}

impl RevisionSyncObject<AttributeHashMap> for ServerDocument {
  fn object_id(&self) -> &str {
    &self.document_id
  }

  fn object_json(&self) -> String {
    self.operations.json_str()
  }

  fn compose(&mut self, other: &DeltaTextOperations) -> Result<(), SyncError> {
    let operations = self.operations.compose(other)?;
    self.operations = operations;
    Ok(())
  }

  fn transform(
    &self,
    other: &DeltaTextOperations,
  ) -> Result<(DeltaTextOperations, DeltaTextOperations), SyncError> {
    let value = self.operations.transform(other)?;
    Ok(value)
  }

  fn set_operations(&mut self, operations: RevisionOperations<AttributeHashMap>) {
    self.operations = operations;
  }
}
