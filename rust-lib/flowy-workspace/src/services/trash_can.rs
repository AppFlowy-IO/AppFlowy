use crate::{
    entities::trash::{RepeatedTrash, Trash},
    errors::WorkspaceError,
    module::WorkspaceDatabase,
};
use std::sync::Arc;

pub struct TrashCan {
    database: Arc<dyn WorkspaceDatabase>,
}

impl TrashCan {
    pub fn new(database: Arc<dyn WorkspaceDatabase>) -> Self { Self { database } }
    pub fn read_trash(&self) -> Result<RepeatedTrash, WorkspaceError> { Ok(RepeatedTrash { items: vec![] }) }

    pub fn add<T: Into<Trash>>(&self, trash: T) { let trash = trash.into(); }

    pub fn remove(&self, trash_id: &str) {}
}
