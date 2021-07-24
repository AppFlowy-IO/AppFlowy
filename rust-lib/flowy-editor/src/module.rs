use crate::{
    errors::EditorError,
    event::EditorEvent,
    handlers::*,
    services::{
        doc_controller::DocController,
        file_manager::{create_dir_if_not_exist, FileManager},
    },
};
use flowy_database::DBConnection;
use flowy_dispatch::prelude::*;
use std::sync::Arc;
use tokio::sync::RwLock;

pub trait EditorDatabase: Send + Sync {
    fn db_connection(&self) -> Result<DBConnection, EditorError>;
}

pub trait EditorUser: Send + Sync {
    fn user_doc_dir(&self) -> Result<String, EditorError>;
}

pub fn create(database: Arc<dyn EditorDatabase>, user: Arc<dyn EditorUser>) -> Module {
    let file_manager = RwLock::new(FileManager::new(user.clone()));
    let doc_controller = DocController::new(database);

    Module::new()
        .name("Flowy-Editor")
        .data(file_manager)
        .data(doc_controller)
        .event(EditorEvent::CreateDoc, create_doc)
        .event(EditorEvent::UpdateDoc, update_doc)
        .event(EditorEvent::ReadDocInfo, read_doc)
        .event(EditorEvent::ReadDocData, read_doc_data)
}
