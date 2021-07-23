use crate::{
    errors::EditorError,
    event::EditorEvent,
    handlers::*,
    services::{
        doc_controller::DocController,
        file_manager::{FileManager, FileManagerConfig},
    },
};
use flowy_database::DBConnection;
use flowy_dispatch::prelude::*;
use std::sync::{Arc, RwLock};

pub trait EditorDatabase: Send + Sync {
    fn db_connection(&self) -> Result<DBConnection, EditorError>;
}

pub struct EditorConfig {
    root: String,
}

impl EditorConfig {
    pub fn new(root: &str) -> Self {
        Self {
            root: root.to_owned(),
        }
    }
}

pub fn create(database: Arc<dyn EditorDatabase>, config: EditorConfig) -> Module {
    let file_manager = RwLock::new(FileManager::new(FileManagerConfig::new(&config.root)));
    let doc_controller = DocController::new(database);

    Module::new()
        .name("Flowy-Editor")
        .data(file_manager)
        .data(doc_controller)
        .event(EditorEvent::CreateDoc, create_doc)
        .event(EditorEvent::UpdateDoc, update_doc)
        .event(EditorEvent::ReadDoc, read_doc)
}
