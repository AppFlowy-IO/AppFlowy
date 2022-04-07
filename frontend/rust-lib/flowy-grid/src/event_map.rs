use crate::event_handler::*;
use crate::manager::GridManager;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::*;
use std::sync::Arc;
use strum_macros::Display;

pub fn create(grid_manager: Arc<GridManager>) -> Module {
    let mut module = Module::new().name(env!("CARGO_PKG_NAME")).data(grid_manager);
    module = module
        .event(GridEvent::GetGridData, get_grid_data_handler)
        .event(GridEvent::GetGridBlocks, get_grid_blocks_handler)
        // Field
        .event(GridEvent::GetFields, get_fields_handler)
        .event(GridEvent::UpdateField, update_field_handler)
        .event(GridEvent::CreateField, create_field_handler)
        .event(GridEvent::DeleteField, delete_field_handler)
        .event(GridEvent::SwitchToField, switch_to_field_handler)
        .event(GridEvent::DuplicateField, duplicate_field_handler)
        // Row
        .event(GridEvent::CreateRow, create_row_handler)
        .event(GridEvent::GetRow, get_row_handler)
        // Cell
        .event(GridEvent::GetCell, get_cell_handler)
        .event(GridEvent::UpdateCell, update_cell_handler)
        // SelectOption
        .event(GridEvent::NewSelectOption, new_select_option_handler)
        .event(GridEvent::ApplySelectOptionChangeset, select_option_changeset_handler)
        .event(GridEvent::GetSelectOptionContext, get_select_option_handler)
        .event(
            GridEvent::ApplySelectOptionCellChangeset,
            select_option_cell_changeset_handler,
        )
        .event(GridEvent::GetEditFieldContext, get_field_context_handler);

    module
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum GridEvent {
    #[event(input = "GridId", output = "Grid")]
    GetGridData = 0,

    #[event(input = "QueryGridBlocksPayload", output = "RepeatedGridBlock")]
    GetGridBlocks = 1,

    #[event(input = "QueryFieldPayload", output = "RepeatedField")]
    GetFields = 10,

    #[event(input = "FieldChangesetPayload")]
    UpdateField = 11,

    #[event(input = "CreateFieldPayload")]
    CreateField = 12,

    #[event(input = "FieldIdentifierPayload")]
    DeleteField = 13,

    #[event(input = "EditFieldPayload", output = "EditFieldContext")]
    SwitchToField = 14,

    #[event(input = "FieldIdentifierPayload")]
    DuplicateField = 15,

    #[event(input = "GetEditFieldContextPayload", output = "EditFieldContext")]
    GetEditFieldContext = 16,

    #[event(input = "SelectOptionName", output = "SelectOption")]
    NewSelectOption = 30,

    #[event(input = "CellIdentifierPayload", output = "SelectOptionContext")]
    GetSelectOptionContext = 31,

    #[event(input = "SelectOptionChangesetPayload")]
    ApplySelectOptionChangeset = 32,

    #[event(input = "CreateRowPayload", output = "Row")]
    CreateRow = 50,

    #[event(input = "RowIdentifierPayload", output = "Row")]
    GetRow = 51,

    #[event(input = "CellIdentifierPayload", output = "Cell")]
    GetCell = 70,

    #[event(input = "CellMetaChangeset")]
    UpdateCell = 71,

    #[event(input = "SelectOptionCellChangesetPayload")]
    ApplySelectOptionCellChangeset = 72,
}
