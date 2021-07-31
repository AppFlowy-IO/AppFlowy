use crate::{
    errors::DocError,
    event::EditorEvent,
    handlers::*,
    services::{doc_controller::DocController, file_manager::FileManager},
};
use flowy_database::DBConnection;
use flowy_dispatch::prelude::*;
use std::sync::Arc;
use tokio::sync::RwLock;

pub trait DocumentDatabase: Send + Sync {
    fn db_connection(&self) -> Result<DBConnection, DocError>;
}

pub trait DocumentUser: Send + Sync {
    fn user_doc_dir(&self) -> Result<String, DocError>;
}

pub fn create(database: Arc<dyn DocumentDatabase>, user: Arc<dyn DocumentUser>) -> Module {
    let file_manager = RwLock::new(FileManager::new(user.clone()));
    let doc_controller = DocController::new(database);

    Module::new()
        .name("flowy-document")
        .data(file_manager)
        .data(doc_controller)
        .event(EditorEvent::CreateDoc, create_doc)
        .event(EditorEvent::UpdateDoc, update_doc)
        .event(EditorEvent::ReadDocInfo, read_doc)
        .event(EditorEvent::ReadDocData, read_doc_data)
}
