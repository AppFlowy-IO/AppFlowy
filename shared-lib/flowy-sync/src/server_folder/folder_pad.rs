use crate::{entities::folder::FolderDelta, errors::CollaborateError, synchronizer::RevisionSyncObject};
use lib_ot::core::{OperationTransform, PhantomAttributes, TextDelta};

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

impl RevisionSyncObject<PhantomAttributes> for ServerFolder {
    fn id(&self) -> &str {
        &self.folder_id
    }

    fn compose(&mut self, other: &TextDelta) -> Result<(), CollaborateError> {
        let new_delta = self.delta.compose(other)?;
        self.delta = new_delta;
        Ok(())
    }

    fn transform(&self, other: &TextDelta) -> Result<(TextDelta, TextDelta), CollaborateError> {
        let value = self.delta.transform(other)?;
        Ok(value)
    }

    fn to_json(&self) -> String {
        self.delta.to_json_str()
    }

    fn set_delta(&mut self, new_delta: TextDelta) {
        self.delta = new_delta;
    }
}
