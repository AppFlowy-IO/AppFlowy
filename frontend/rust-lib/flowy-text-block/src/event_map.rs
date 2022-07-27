use crate::event_handler::*;
use crate::TextBlockManager;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::Module;
use std::sync::Arc;
use strum_macros::Display;

pub fn create(block_manager: Arc<TextBlockManager>) -> Module {
    let mut module = Module::new().name(env!("CARGO_PKG_NAME")).data(block_manager);

    module = module
        .event(TextBlockEvent::GetBlockData, get_block_data_handler)
        .event(TextBlockEvent::ApplyDelta, apply_delta_handler)
        .event(TextBlockEvent::ExportDocument, export_handler);

    module
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum TextBlockEvent {
    #[event(input = "TextBlockIdPB", output = "TextBlockDeltaPB")]
    GetBlockData = 0,

    #[event(input = "TextBlockDeltaPB", output = "TextBlockDeltaPB")]
    ApplyDelta = 1,

    #[event(input = "ExportPayloadPB", output = "ExportDataPB")]
    ExportDocument = 2,
}
