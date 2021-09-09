use crate::{
    errors::DocError,
    event::EditorEvent,
    handlers::*,
    services::{doc_controller::DocController, file_manager::FileManager, server::construct_doc_server},
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
    fn user_id(&self) -> Result<String, DocError>;
    fn token(&self) -> Result<String, DocError>;
}

pub fn create(database: Arc<dyn DocumentDatabase>, user: Arc<dyn DocumentUser>) -> Module {
    let server = construct_doc_server();
    let file_manager = RwLock::new(FileManager::new(user.clone()));
    let doc_controller = DocController::new(database, server.clone(), user.clone());

    Module::new()
        .name("flowy-document")
        .data(file_manager)
        .data(doc_controller)
        .event(EditorEvent::CreateDoc, create_doc_handler)
        .event(EditorEvent::UpdateDoc, update_doc_handler)
        .event(EditorEvent::ReadDoc, read_doc_handler)
        .event(EditorEvent::DeleteDoc, delete_doc_handler)
}
