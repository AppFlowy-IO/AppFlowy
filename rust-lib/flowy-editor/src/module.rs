use crate::{
    errors::EditorError,
    event::EditorEvent,
    handlers::*,
    services::file_manager::FileManager,
};
use flowy_database::DBConnection;
use flowy_dispatch::prelude::*;
use std::sync::{Arc, RwLock};

pub trait EditorDatabase: Send + Sync {
    fn db_connection(&self) -> Result<DBConnection, EditorError>;
}

pub fn create() -> Module {
    let file_manager = RwLock::new(FileManager::new());

    Module::new()
        .name("Flowy-Editor")
        .data(file_manager)
        .event(EditorEvent::CreateDoc, create_doc)
}
