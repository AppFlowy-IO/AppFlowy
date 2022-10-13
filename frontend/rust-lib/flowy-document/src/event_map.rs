use crate::event_handler::*;
use crate::DocumentEditorManager;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::Module;
use std::sync::Arc;
use strum_macros::Display;

pub fn create(document_manager: Arc<DocumentEditorManager>) -> Module {
    let mut module = Module::new().name(env!("CARGO_PKG_NAME")).data(document_manager);

    module = module
        .event(DocumentEvent::GetDocument, get_document_handler)
        .event(DocumentEvent::ApplyEdit, apply_edit_handler)
        .event(DocumentEvent::ExportDocument, export_handler);

    module
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum DocumentEvent {
    #[event(input = "DocumentIdPB", output = "DocumentSnapshotPB")]
    GetDocument = 0,

    #[event(input = "EditPayloadPB")]
    ApplyEdit = 1,

    #[event(input = "ExportPayloadPB", output = "ExportDataPB")]
    ExportDocument = 2,
}
