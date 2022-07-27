use crate::event_handler::*;
use crate::manager::GridManager;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::*;
use std::sync::Arc;
use strum_macros::Display;

pub fn create(grid_manager: Arc<GridManager>) -> Module {
    let mut module = Module::new().name(env!("CARGO_PKG_NAME")).data(grid_manager);
    module = module
        .event(GridEvent::GetGrid, get_grid_handler)
        .event(GridEvent::GetGridBlocks, get_grid_blocks_handler)
        .event(GridEvent::GetGridSetting, get_grid_setting_handler)
        .event(GridEvent::UpdateGridSetting, update_grid_setting_handler)
        // Field
        .event(GridEvent::GetFields, get_fields_handler)
        .event(GridEvent::UpdateField, update_field_handler)
        .event(GridEvent::InsertField, insert_field_handler)
        .event(GridEvent::UpdateFieldTypeOption, update_field_type_option_handler)
        .event(GridEvent::DeleteField, delete_field_handler)
        .event(GridEvent::SwitchToField, switch_to_field_handler)
        .event(GridEvent::DuplicateField, duplicate_field_handler)
        .event(GridEvent::MoveItem, move_item_handler)
        .event(GridEvent::GetFieldTypeOption, get_field_type_option_data_handler)
        .event(GridEvent::CreateFieldTypeOption, create_field_type_option_data_handler)
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
        .event(GridEvent::GetSelectOptionCellData, get_select_option_handler)
        .event(GridEvent::UpdateSelectOptionCell, update_select_option_cell_handler)
        // Date
        .event(GridEvent::UpdateDateCell, update_date_cell_handler);

    module
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum GridEvent {
    #[event(input = "GridIdPB", output = "GridPB")]
    GetGrid = 0,

    #[event(input = "QueryGridBlocksPayloadPB", output = "RepeatedGridBlockPB")]
    GetGridBlocks = 1,

    #[event(input = "GridIdPB", output = "GridSettingPB")]
    GetGridSetting = 2,

    #[event(input = "GridIdPB", input = "GridSettingChangesetPayloadPB")]
    UpdateGridSetting = 3,

    #[event(input = "QueryFieldPayloadPB", output = "RepeatedGridFieldPB")]
    GetFields = 10,

    #[event(input = "FieldChangesetPayloadPB")]
    UpdateField = 11,

    #[event(input = "UpdateFieldTypeOptionPayloadPB")]
    UpdateFieldTypeOption = 12,

    #[event(input = "InsertFieldPayloadPB")]
    InsertField = 13,

    #[event(input = "DeleteFieldPayloadPB")]
    DeleteField = 14,

    #[event(input = "EditFieldPayloadPB", output = "FieldTypeOptionDataPB")]
    SwitchToField = 20,

    #[event(input = "DuplicateFieldPayloadPB")]
    DuplicateField = 21,

    #[event(input = "MoveItemPayloadPB")]
    MoveItem = 22,

    #[event(input = "GridFieldTypeOptionIdPB", output = "FieldTypeOptionDataPB")]
    GetFieldTypeOption = 23,

    #[event(input = "CreateFieldPayloadPB", output = "FieldTypeOptionDataPB")]
    CreateFieldTypeOption = 24,

    #[event(input = "CreateSelectOptionPayloadPB", output = "SelectOptionPB")]
    NewSelectOption = 30,

    #[event(input = "GridCellIdPB", output = "SelectOptionCellDataPB")]
    GetSelectOptionCellData = 31,

    #[event(input = "SelectOptionChangesetPayloadPB")]
    UpdateSelectOption = 32,

    #[event(input = "CreateRowPayloadPB", output = "GridRowPB")]
    CreateRow = 50,

    #[event(input = "GridRowIdPB", output = "OptionalRowPB")]
    GetRow = 51,

    #[event(input = "GridRowIdPB")]
    DeleteRow = 52,

    #[event(input = "GridRowIdPB")]
    DuplicateRow = 53,

    #[event(input = "GridCellIdPB", output = "GridCellPB")]
    GetCell = 70,

    #[event(input = "CellChangesetPB")]
    UpdateCell = 71,

    #[event(input = "SelectOptionCellChangesetPayloadPB")]
    UpdateSelectOptionCell = 72,

    #[event(input = "DateChangesetPayloadPB")]
    UpdateDateCell = 80,
}
