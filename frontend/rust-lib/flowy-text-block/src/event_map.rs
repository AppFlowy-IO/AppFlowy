use crate::event_handler::*;
use crate::TextEditorManager;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::Module;
use std::sync::Arc;
use strum_macros::Display;

pub fn create(block_manager: Arc<TextEditorManager>) -> Module {
    let mut module = Module::new().name(env!("CARGO_PKG_NAME")).data(block_manager);

    module = module
        .event(TextBlockEvent::GetTextBlock, get_text_block_handler)
        .event(TextBlockEvent::ApplyEdit, apply_edit_handler)
        .event(TextBlockEvent::ExportDocument, export_handler);

    module
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum TextBlockEvent {
    #[event(input = "TextBlockIdPB", output = "TextBlockPB")]
    GetTextBlock = 0,

    #[event(input = "EditPayloadPB")]
    ApplyEdit = 1,

    #[event(input = "ExportPayloadPB", output = "ExportDataPB")]
    ExportDocument = 2,
}
