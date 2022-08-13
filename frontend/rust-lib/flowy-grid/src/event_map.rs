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
        .event(GridEvent::UpdateDateCell, update_date_cell_handler)
        // Group
        .event(GridEvent::CreateBoardCard, create_row_handler)
        .event(GridEvent::GetGroup, get_groups_handler);

    module
}

/// [GridEvent] defines events that are used to interact with the Grid. You could check [this](https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/backend/protobuf)
/// out, it includes how to use these annotations: input, output, etc.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum GridEvent {
    /// [GetGrid] event is used to get the [GridPB]
    ///
    /// The event handler accepts a [GridIdPB] and returns a [GridPB] if there are no errors.
    #[event(input = "GridIdPB", output = "GridPB")]
    GetGrid = 0,

    /// [GetGridBlocks] event is used to get the grid's block.
    ///
    /// The event handler accepts a [QueryBlocksPayloadPB] and returns a [RepeatedBlockPB]
    /// if there are no errors.
    #[event(input = "QueryBlocksPayloadPB", output = "RepeatedBlockPB")]
    GetGridBlocks = 1,

    /// [GetGridSetting] event is used to get the grid's settings.
    ///
    /// The event handler accepts [GridIdPB] and return [GridSettingPB]
    /// if there is no errors.
    #[event(input = "GridIdPB", output = "GridSettingPB")]
    GetGridSetting = 2,

    /// [UpdateGridSetting] event is used to update the grid's settings.
    ///
    /// The event handler accepts [GridIdPB] and return errors if failed to modify the grid's settings.
    #[event(input = "GridIdPB", input = "GridSettingChangesetPayloadPB")]
    UpdateGridSetting = 3,

    /// [GetFields] event is used to get the grid's settings.
    ///
    /// The event handler accepts a [QueryFieldPayloadPB] and returns a [RepeatedFieldPB]
    /// if there are no errors.
    #[event(input = "QueryFieldPayloadPB", output = "RepeatedFieldPB")]
    GetFields = 10,

    /// [UpdateField] event is used to update a field's attributes.
    ///
    /// The event handler accepts a [FieldChangesetPayloadPB] and returns errors if failed to modify the
    /// field.
    #[event(input = "FieldChangesetPayloadPB")]
    UpdateField = 11,

    /// [UpdateFieldTypeOption] event is used to update the field's type option data. Certain field
    /// types have user-defined options such as color, date format, number format, or a list of values
    /// for a multi-select list. These options are defined within a specialization of the
    /// FieldTypeOption class.
    ///
    /// Check out [this](https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid#fieldtype)
    /// for more information.
    ///
    /// The event handler accepts a [UpdateFieldTypeOptionPayloadPB] and returns errors if failed to modify the
    /// field.
    #[event(input = "UpdateFieldTypeOptionPayloadPB")]
    UpdateFieldTypeOption = 12,

    /// [InsertField] event is used to insert a new Field. If the Field already exists, the event
    /// handler will replace the value with the new Field value.
    #[event(input = "InsertFieldPayloadPB")]
    InsertField = 13,

    /// [DeleteField] event is used to delete a Field. [DeleteFieldPayloadPB] is the context that
    /// is used to delete the field from the Grid.
    #[event(input = "DeleteFieldPayloadPB")]
    DeleteField = 14,

    /// [SwitchToField] event is used to update the current Field's type.
    /// It will insert a new FieldTypeOptionData if the new FieldType doesn't exist before, otherwise
    /// reuse the existing FieldTypeOptionData. You could check the [GridRevisionPad] for more details.
    #[event(input = "EditFieldPayloadPB", output = "FieldTypeOptionDataPB")]
    SwitchToField = 20,

    /// [DuplicateField] event is used to duplicate a Field. The duplicated field data is kind of
    /// deep copy of the target field. The passed in [DuplicateFieldPayloadPB] is the context that is
    /// used to duplicate the field.
    ///
    /// Return errors if failed to duplicate the field.
    ///
    #[event(input = "DuplicateFieldPayloadPB")]
    DuplicateField = 21,

    /// [MoveItem] event is used to move an item. For the moment, Item has two types defined in
    /// [MoveItemTypePB].
    #[event(input = "MoveItemPayloadPB")]
    MoveItem = 22,

    /// [FieldTypeOptionIdPB] event is used to get the FieldTypeOption data for a specific field type.
    ///
    /// Check out the [FieldTypeOptionDataPB] for more details. If the [FieldTypeOptionData] does exist
    /// for the target type, the [TypeOptionBuilder] will create the default data for that type.
    ///
    /// Return the [FieldTypeOptionDataPB] if there are no errors.
    #[event(input = "FieldTypeOptionIdPB", output = "FieldTypeOptionDataPB")]
    GetFieldTypeOption = 23,

    /// [CreateFieldTypeOption] event is used to create a new FieldTypeOptionData.
    #[event(input = "CreateFieldPayloadPB", output = "FieldTypeOptionDataPB")]
    CreateFieldTypeOption = 24,

    /// [NewSelectOption] event is used to create a new select option. Returns a [SelectOptionPB] if
    /// there are no errors.
    #[event(input = "CreateSelectOptionPayloadPB", output = "SelectOptionPB")]
    NewSelectOption = 30,

    /// [GetSelectOptionCellData] event is used to get the select option data for cell editing.
    /// [GridCellIdPB] locate which cell data that will be read from. The return value, [SelectOptionCellDataPB]
    /// contains the available options and the currently selected options.
    #[event(input = "GridCellIdPB", output = "SelectOptionCellDataPB")]
    GetSelectOptionCellData = 31,

    /// [UpdateSelectOption] event is used to update a FieldTypeOptionData whose field_type is
    /// FieldType::SingleSelect or FieldType::MultiSelect.
    ///
    /// This event may trigger the GridNotification::DidUpdateCell event.
    /// For example, GridNotification::DidUpdateCell will be triggered if the [SelectOptionChangesetPayloadPB]
    /// carries a change that updates the name of the option.
    #[event(input = "SelectOptionChangesetPayloadPB")]
    UpdateSelectOption = 32,

    #[event(input = "CreateRowPayloadPB", output = "RowPB")]
    CreateRow = 50,

    /// [GetRow] event is used to get the row data,[RowPB]. [OptionalRowPB] is a wrapper that enables
    /// to return a nullable row data.
    #[event(input = "RowIdPB", output = "OptionalRowPB")]
    GetRow = 51,

    #[event(input = "RowIdPB")]
    DeleteRow = 52,

    #[event(input = "RowIdPB")]
    DuplicateRow = 53,

    #[event(input = "GridCellIdPB", output = "GridCellPB")]
    GetCell = 70,

    /// [UpdateCell] event is used to update the cell content. The passed in data, [CellChangesetPB],
    /// carries the changes that will be applied to the cell content by calling `update_cell` function.
    ///
    /// The 'content' property of the [CellChangesetPB] is a String type. It can be used directly if the
    /// cell uses string data. For example, the TextCell or NumberCell.
    ///
    /// But,it can be treated as a generic type, because we can use [serde] to deserialize the string
    /// into a specific data type. For the moment, the 'content' will be deserialized to a concrete type
    /// when the FieldType is SingleSelect, DateTime, and MultiSelect. Please see
    /// the [UpdateSelectOptionCell] and [UpdateDateCell] events for more details.
    #[event(input = "CellChangesetPB")]
    UpdateCell = 71,

    /// [UpdateSelectOptionCell] event is used to update a select option cell's data. [SelectOptionCellChangesetPayloadPB]
    /// contains options that will be deleted or inserted. It can be cast to [CellChangesetPB] that
    /// will be used by the `update_cell` function.
    #[event(input = "SelectOptionCellChangesetPayloadPB")]
    UpdateSelectOptionCell = 72,

    /// [UpdateDateCell] event is used to update a date cell's data. [DateChangesetPayloadPB]
    /// contains the date and the time string. It can be cast to [CellChangesetPB] that
    /// will be used by the `update_cell` function.
    #[event(input = "DateChangesetPayloadPB")]
    UpdateDateCell = 80,

    #[event(input = "GridIdPB", output = "RepeatedGridGroupPB")]
    GetGroup = 100,

    #[event(input = "CreateBoardCardPayloadPB", output = "RowPB")]
    CreateBoardCard = 110,
}
