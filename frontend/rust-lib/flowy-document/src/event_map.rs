use crate::event_handler::*;
use crate::DocumentManager;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::AFPlugin;
use std::sync::Arc;
use strum_macros::Display;

pub fn init(document_manager: Arc<DocumentManager>) -> AFPlugin {
    let mut plugin = AFPlugin::new().name(env!("CARGO_PKG_NAME")).state(document_manager);

    plugin = plugin
        .event(DocumentEvent::GetDocument, get_document_handler)
        .event(DocumentEvent::ApplyEdit, apply_edit_handler)
        .event(DocumentEvent::ExportDocument, export_handler);

    plugin
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum DocumentEvent {
    #[event(input = "OpenDocumentContextPB", output = "DocumentSnapshotPB")]
    GetDocument = 0,

    #[event(input = "EditPayloadPB")]
    ApplyEdit = 1,

    #[event(input = "ExportPayloadPB", output = "ExportDataPB")]
    ExportDocument = 2,
}
