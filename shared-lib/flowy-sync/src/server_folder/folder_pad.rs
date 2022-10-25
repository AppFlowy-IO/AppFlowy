use crate::synchronizer::{RevisionOperations, RevisionSynchronizer};
use crate::{errors::CollaborateError, synchronizer::RevisionSyncObject};
use lib_ot::core::{DeltaOperationBuilder, DeltaOperations, EmptyAttributes, OperationTransform};

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

    fn compose(&mut self, other: &FolderOperations) -> Result<(), CollaborateError> {
        let operations = self.operations.compose(other)?;
        self.operations = operations;
        Ok(())
    }

    fn transform(&self, other: &FolderOperations) -> Result<(FolderOperations, FolderOperations), CollaborateError> {
        let value = self.operations.transform(other)?;
        Ok(value)
    }

    fn set_operations(&mut self, operations: RevisionOperations<EmptyAttributes>) {
        self.operations = operations;
    }
}
