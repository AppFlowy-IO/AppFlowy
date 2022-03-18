use crate::event_handler::*;
use crate::TextBlockManager;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::Module;
use std::sync::Arc;
use strum_macros::Display;

pub fn create(block_manager: Arc<TextBlockManager>) -> Module {
    let mut module = Module::new().name(env!("CARGO_PKG_NAME")).data(block_manager);

    module = module
        .event(BlockEvent::GetBlockData, get_block_data_handler)
        .event(BlockEvent::ApplyDelta, apply_delta_handler)
        .event(BlockEvent::ExportDocument, export_handler);

    module
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum BlockEvent {
    #[event(input = "BlockId", output = "BlockDelta")]
    GetBlockData = 0,

    #[event(input = "BlockDelta", output = "BlockDelta")]
    ApplyDelta = 1,

    #[event(input = "ExportPayload", output = "ExportData")]
    ExportDocument = 2,
}
