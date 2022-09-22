use crate::synchronizer::RevisionOperations;
use crate::{errors::CollaborateError, synchronizer::RevisionSyncObject};
use lib_ot::core::{Delta, EmptyAttributes, OperationTransform};

pub struct ServerFolder {
    folder_id: String,
    operations: Delta,
}

impl ServerFolder {
    pub fn from_delta(folder_id: &str, operations: Delta) -> Self {
        Self {
            folder_id: folder_id.to_owned(),
            operations,
        }
    }
}

impl RevisionSyncObject<EmptyAttributes> for ServerFolder {
    fn id(&self) -> &str {
        &self.folder_id
    }

    fn compose(&mut self, other: &Delta) -> Result<(), CollaborateError> {
        let new_delta = self.operations.compose(other)?;
        self.operations = new_delta;
        Ok(())
    }

    fn transform(&self, other: &Delta) -> Result<(Delta, Delta), CollaborateError> {
        let value = self.operations.transform(other)?;
        Ok(value)
    }

    fn to_json(&self) -> String {
        self.operations.json_str()
    }

    fn set_operations(&mut self, operations: RevisionOperations<EmptyAttributes>) {
        self.operations = operations;
    }
}
