use crate::{entities::trash::RepeatedTrash, errors::WorkspaceError};

pub struct TrashController {}

impl TrashController {
    pub fn new() -> Self { Self {} }
    pub fn read_trash(&self) -> Result<RepeatedTrash, WorkspaceError> { Ok(RepeatedTrash { items: vec![] }) }
}
