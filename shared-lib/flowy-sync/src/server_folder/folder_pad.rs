use crate::{entities::folder::FolderDelta, errors::CollaborateError, synchronizer::RevisionSyncObject};
use lib_ot::core::{Delta, EmptyAttributes, OperationTransform};

pub struct ServerFolder {
    folder_id: String,
    delta: FolderDelta,
}

impl ServerFolder {
    pub fn from_delta(folder_id: &str, delta: FolderDelta) -> Self {
        Self {
            folder_id: folder_id.to_owned(),
            delta,
        }
    }
}

impl RevisionSyncObject<EmptyAttributes> for ServerFolder {
    fn id(&self) -> &str {
        &self.folder_id
    }

    fn compose(&mut self, other: &Delta) -> Result<(), CollaborateError> {
        let new_delta = self.delta.compose(other)?;
        self.delta = new_delta;
        Ok(())
    }

    fn transform(&self, other: &Delta) -> Result<(Delta, Delta), CollaborateError> {
        let value = self.delta.transform(other)?;
        Ok(value)
    }

    fn to_json(&self) -> String {
        self.delta.json_str()
    }

    fn set_delta(&mut self, new_delta: Delta) {
        self.delta = new_delta;
    }
}
