use crate::{event::EditorEvent, handlers::*, services::file_manager::FileManager};
use flowy_dispatch::prelude::*;
use std::sync::{Arc, RwLock};

pub fn create() -> Module {
    let file_manager = RwLock::new(FileManager::new());

    Module::new()
        .name("Flowy-Editor")
        .data(file_manager)
        .event(EditorEvent::CreateDoc, create_doc)
}
