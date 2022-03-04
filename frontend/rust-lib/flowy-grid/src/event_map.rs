use crate::event_handler::*;
use crate::manager::GridManager;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::*;
use std::sync::Arc;
use strum_macros::Display;

pub fn create(grid_manager: Arc<GridManager>) -> Module {
    let mut module = Module::new().name(env!("CARGO_PKG_NAME")).data(grid_manager);
    module = module
        .event(GridEvent::CreateGrid, create_grid_handler)
        .event(GridEvent::OpenGrid, open_grid_handler)
        .event(GridEvent::GetRows, get_rows_handler)
        .event(GridEvent::GetFields, get_fields_handler)
        .event(GridEvent::CreateRow, create_row_handler);

    module
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum GridEvent {
    #[event(input = "CreateGridPayload", output = "Grid")]
    CreateGrid = 0,

    #[event(input = "GridId", output = "Grid")]
    OpenGrid = 1,

    #[event(input = "RepeatedRowOrder", output = "RepeatedRow")]
    GetRows = 2,

    #[event(input = "RepeatedFieldOrder", output = "RepeatedField")]
    GetFields = 3,

    #[event(input = "GridId")]
    CreateRow = 4,
}
