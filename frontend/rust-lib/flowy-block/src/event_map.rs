use crate::event_handler::*;
use crate::BlockManager;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::Module;
use std::sync::Arc;
use strum_macros::Display;

pub fn create(block_manager: Arc<BlockManager>) -> Module {
    let mut module = Module::new().name(env!("CARGO_PKG_NAME")).data(block_manager);

    module = module
        .event(BlockEvent::ApplyDocDelta, apply_delta_handler)
        .event(BlockEvent::ExportDocument, export_handler);

    module
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum BlockEvent {
    #[event(input = "BlockDelta", output = "BlockDelta")]
    ApplyDocDelta = 0,

    #[event(input = "ExportPayload", output = "ExportData")]
    ExportDocument = 1,
}
