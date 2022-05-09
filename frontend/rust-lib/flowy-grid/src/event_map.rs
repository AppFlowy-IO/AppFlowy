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
        .event(GridEvent::InsertField, insert_field_handler)
        .event(GridEvent::DeleteField, delete_field_handler)
        .event(GridEvent::SwitchToField, switch_to_field_handler)
        .event(GridEvent::DuplicateField, duplicate_field_handler)
        .event(GridEvent::GetEditFieldContext, get_field_context_handler)
        .event(GridEvent::MoveItem, move_item_handler)
        .event(GridEvent::GetFieldTypeOption, get_field_type_option_data_handler)
        // Row
        .event(GridEvent::CreateRow, create_row_handler)
        .event(GridEvent::GetRow, get_row_handler)
        .event(GridEvent::DeleteRow, delete_row_handler)
        .event(GridEvent::DuplicateRow, duplicate_row_handler)
        // Cell
        .event(GridEvent::GetCell, get_cell_handler)
        .event(GridEvent::UpdateCell, update_cell_handler)
        // SelectOption
        .event(GridEvent::NewSelectOption, new_select_option_handler)
        .event(GridEvent::UpdateSelectOption, update_select_option_handler)
        .event(GridEvent::GetSelectOptionContext, get_select_option_handler)
        .event(GridEvent::UpdateCellSelectOption, update_cell_select_option_handler);

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

    #[event(input = "InsertFieldPayload")]
    InsertField = 12,

    #[event(input = "FieldIdentifierPayload")]
    DeleteField = 13,

    #[event(input = "EditFieldPayload", output = "EditFieldContext")]
    SwitchToField = 14,

    #[event(input = "FieldIdentifierPayload")]
    DuplicateField = 15,

    #[event(input = "EditFieldPayload", output = "EditFieldContext")]
    GetEditFieldContext = 16,

    #[event(input = "MoveItemPayload")]
    MoveItem = 17,

    #[event(input = "EditFieldPayload", output = "FieldTypeOptionData")]
    GetFieldTypeOption = 18,

    #[event(input = "CreateSelectOptionPayload", output = "SelectOption")]
    NewSelectOption = 30,

    #[event(input = "CellIdentifierPayload", output = "SelectOptionContext")]
    GetSelectOptionContext = 31,

    #[event(input = "SelectOptionChangesetPayload")]
    UpdateSelectOption = 32,

    #[event(input = "CreateRowPayload", output = "Row")]
    CreateRow = 50,

    #[event(input = "RowIdentifierPayload", output = "Row")]
    GetRow = 51,

    #[event(input = "RowIdentifierPayload")]
    DeleteRow = 52,

    #[event(input = "RowIdentifierPayload")]
    DuplicateRow = 53,

    #[event(input = "CellIdentifierPayload", output = "Cell")]
    GetCell = 70,

    #[event(input = "CellChangeset")]
    UpdateCell = 71,

    #[event(input = "SelectOptionCellChangesetPayload")]
    UpdateCellSelectOption = 72,
}
