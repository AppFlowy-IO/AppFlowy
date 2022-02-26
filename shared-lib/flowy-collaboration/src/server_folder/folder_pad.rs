use crate::{entities::folder_info::FolderDelta, errors::CollaborateError, synchronizer::RevisionSyncObject};
use lib_ot::core::{Delta, OperationTransformable, PlainAttributes};

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

impl RevisionSyncObject<PlainAttributes> for ServerFolder {
    fn id(&self) -> &str {
        &self.folder_id
    }

    fn compose(&mut self, other: &Delta<PlainAttributes>) -> Result<(), CollaborateError> {
        let new_delta = self.delta.compose(other)?;
        self.delta = new_delta;
        Ok(())
    }

    fn transform(
        &self,
        other: &Delta<PlainAttributes>,
    ) -> Result<(Delta<PlainAttributes>, Delta<PlainAttributes>), CollaborateError> {
        let value = self.delta.transform(other)?;
        Ok(value)
    }

    fn to_json(&self) -> String {
        self.delta.to_json()
    }

    fn set_delta(&mut self, new_delta: Delta<PlainAttributes>) {
        self.delta = new_delta;
    }
}
