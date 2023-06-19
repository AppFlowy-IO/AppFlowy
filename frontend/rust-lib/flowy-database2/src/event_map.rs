use std::sync::Arc;

use strum_macros::Display;

use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::*;

use crate::event_handler::*;
use crate::manager::DatabaseManager2;

pub fn init(database_manager: Arc<DatabaseManager2>) -> AFPlugin {
  let plugin = AFPlugin::new()
    .name(env!("CARGO_PKG_NAME"))
    .state(database_manager);
  plugin
        .event(DatabaseEvent::GetDatabase, get_database_data_handler)
        .event(DatabaseEvent::GetDatabaseId, get_database_id_handler)
        .event(DatabaseEvent::GetDatabaseSetting, get_database_setting_handler)
        .event(DatabaseEvent::UpdateDatabaseSetting, update_database_setting_handler)
        .event(DatabaseEvent::GetAllFilters, get_all_filters_handler)
        .event(DatabaseEvent::GetAllSorts, get_all_sorts_handler)
        .event(DatabaseEvent::DeleteAllSorts, delete_all_sorts_handler)
        // Field
        .event(DatabaseEvent::GetFields, get_fields_handler)
        .event(DatabaseEvent::GetPrimaryField, get_primary_field_handler)
        .event(DatabaseEvent::UpdateField, update_field_handler)
        .event(DatabaseEvent::UpdateFieldTypeOption, update_field_type_option_handler)
        .event(DatabaseEvent::DeleteField, delete_field_handler)
        .event(DatabaseEvent::UpdateFieldType, switch_to_field_handler)
        .event(DatabaseEvent::DuplicateField, duplicate_field_handler)
        .event(DatabaseEvent::MoveField, move_field_handler)
        .event(DatabaseEvent::GetTypeOption, get_field_type_option_data_handler)
        .event(DatabaseEvent::CreateTypeOption, create_field_type_option_data_handler)
        // Row
        .event(DatabaseEvent::CreateRow, create_row_handler)
        .event(DatabaseEvent::GetRow, get_row_handler)
        .event(DatabaseEvent::GetRowMeta, get_row_meta_handler)
        .event(DatabaseEvent::UpdateRowMeta, update_row_meta_handler)
        .event(DatabaseEvent::DeleteRow, delete_row_handler)
        .event(DatabaseEvent::DuplicateRow, duplicate_row_handler)
        .event(DatabaseEvent::MoveRow, move_row_handler)
        // Cell
        .event(DatabaseEvent::GetCell, get_cell_handler)
        .event(DatabaseEvent::UpdateCell, update_cell_handler)
        // SelectOption
        .event(DatabaseEvent::CreateSelectOption, new_select_option_handler)
        .event(DatabaseEvent::InsertOrUpdateSelectOption, insert_or_update_select_option_handler)
        .event(DatabaseEvent::DeleteSelectOption, delete_select_option_handler)
        .event(DatabaseEvent::GetSelectOptionCellData, get_select_option_handler)
        .event(DatabaseEvent::UpdateSelectOptionCell, update_select_option_cell_handler)
        // Checklist
        .event(DatabaseEvent::GetChecklistCellData, get_checklist_cell_data_handler)
        .event(DatabaseEvent::UpdateChecklistCell, update_checklist_cell_handler)
        // Date
        .event(DatabaseEvent::UpdateDateCell, update_date_cell_handler)
        // Group
        .event(DatabaseEvent::MoveGroup, move_group_handler)
        .event(DatabaseEvent::MoveGroupRow, move_group_row_handler)
        .event(DatabaseEvent::GetGroups, get_groups_handler)
        .event(DatabaseEvent::GetGroup, get_group_handler)
        .event(DatabaseEvent::SetGroupByField, set_group_by_field_handler)
        .event(DatabaseEvent::UpdateGroup, update_group_handler)
        // Database
        .event(DatabaseEvent::GetDatabases, get_databases_handler)
        // Calendar
        .event(DatabaseEvent::GetAllCalendarEvents, get_calendar_events_handler)
        .event(DatabaseEvent::GetNoDateCalendarEvents, get_no_date_calendar_events_handler)
        .event(DatabaseEvent::GetCalendarEvent, get_calendar_event_handler)
        .event(DatabaseEvent::MoveCalendarEvent, move_calendar_event_handler)
        // Layout setting
        .event(DatabaseEvent::SetLayoutSetting, set_layout_setting_handler)
        .event(DatabaseEvent::GetLayoutSetting, get_layout_setting_handler)
        .event(DatabaseEvent::CreateDatabaseView, create_database_view)
        .event(DatabaseEvent::ExportCSV, export_csv_handler)
}

/// [DatabaseEvent] defines events that are used to interact with the Grid. You could check [this](https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/backend/protobuf)
/// out, it includes how to use these annotations: input, output, etc.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum DatabaseEvent {
  /// [GetDatabase] event is used to get the [DatabasePB]
  ///
  /// The event handler accepts a [DatabaseViewIdPB] and returns a [DatabasePB] if there are no errors.
  #[event(input = "DatabaseViewIdPB", output = "DatabasePB")]
  GetDatabase = 0,

  #[event(input = "DatabaseViewIdPB", output = "DatabaseIdPB")]
  GetDatabaseId = 1,

  /// [GetDatabaseSetting] event is used to get the database's settings.
  ///
  /// The event handler accepts [DatabaseViewIdPB] and return [DatabaseViewSettingPB]
  /// if there is no errors.
  #[event(input = "DatabaseViewIdPB", output = "DatabaseViewSettingPB")]
  GetDatabaseSetting = 2,

  /// [UpdateDatabaseSetting] event is used to update the database's settings.
  ///
  /// The event handler accepts [DatabaseSettingChangesetPB] and return errors if failed to modify the grid's settings.
  #[event(input = "DatabaseSettingChangesetPB")]
  UpdateDatabaseSetting = 3,

  #[event(input = "DatabaseViewIdPB", output = "RepeatedFilterPB")]
  GetAllFilters = 4,

  #[event(input = "DatabaseViewIdPB", output = "RepeatedSortPB")]
  GetAllSorts = 5,

  #[event(input = "DatabaseViewIdPB")]
  DeleteAllSorts = 6,

  /// [GetFields] event is used to get the database's fields.
  ///
  /// The event handler accepts a [GetFieldPayloadPB] and returns a [RepeatedFieldPB]
  /// if there are no errors.
  #[event(input = "GetFieldPayloadPB", output = "RepeatedFieldPB")]
  GetFields = 10,

  /// [UpdateField] event is used to update a field's attributes.
  ///
  /// The event handler accepts a [FieldChangesetPB] and returns errors if failed to modify the
  /// field.
  #[event(input = "FieldChangesetPB")]
  UpdateField = 11,

  /// [UpdateFieldTypeOption] event is used to update the field's type-option data. Certain field
  /// types have user-defined options such as color, date format, number format, or a list of values
  /// for a multi-select list. These options are defined within a specialization of the
  /// FieldTypeOption class.
  ///
  /// Check out [this](https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid#fieldtype)
  /// for more information.
  ///
  /// The event handler accepts a [TypeOptionChangesetPB] and returns errors if failed to modify the
  /// field.
  #[event(input = "TypeOptionChangesetPB")]
  UpdateFieldTypeOption = 12,

  /// [DeleteField] event is used to delete a Field. [DeleteFieldPayloadPB] is the context that
  /// is used to delete the field from the Database.
  #[event(input = "DeleteFieldPayloadPB")]
  DeleteField = 14,

  /// [UpdateFieldType] event is used to update the current Field's type.
  /// It will insert a new FieldTypeOptionData if the new FieldType doesn't exist before, otherwise
  /// reuse the existing FieldTypeOptionData. You could check the [DatabaseRevisionPad] for more details.
  #[event(input = "UpdateFieldTypePayloadPB")]
  UpdateFieldType = 20,

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
  #[event(input = "MoveFieldPayloadPB")]
  MoveField = 22,

  /// [TypeOptionPathPB] event is used to get the FieldTypeOption data for a specific field type.
  ///
  /// Check out the [TypeOptionPB] for more details. If the [FieldTypeOptionData] does exist
  /// for the target type, the [TypeOptionBuilder] will create the default data for that type.
  ///
  /// Return the [TypeOptionPB] if there are no errors.
  #[event(input = "TypeOptionPathPB", output = "TypeOptionPB")]
  GetTypeOption = 23,

  /// [CreateTypeOption] event is used to create a new FieldTypeOptionData.
  #[event(input = "CreateFieldPayloadPB", output = "TypeOptionPB")]
  CreateTypeOption = 24,

  #[event(input = "DatabaseViewIdPB", output = "FieldPB")]
  GetPrimaryField = 25,

  /// [CreateSelectOption] event is used to create a new select option. Returns a [SelectOptionPB] if
  /// there are no errors.
  #[event(input = "CreateSelectOptionPayloadPB", output = "SelectOptionPB")]
  CreateSelectOption = 30,

  /// [GetSelectOptionCellData] event is used to get the select option data for cell editing.
  /// [CellIdPB] locate which cell data that will be read from. The return value, [SelectOptionCellDataPB]
  /// contains the available options and the currently selected options.
  #[event(input = "CellIdPB", output = "SelectOptionCellDataPB")]
  GetSelectOptionCellData = 31,

  /// [InsertOrUpdateSelectOption] event is used to update a FieldTypeOptionData whose field_type is
  /// FieldType::SingleSelect or FieldType::MultiSelect.
  ///
  /// This event may trigger the DatabaseNotification::DidUpdateCell event.
  /// For example, DatabaseNotification::DidUpdateCell will be triggered if the [SelectOptionChangesetPB]
  /// carries a change that updates the name of the option.
  #[event(input = "RepeatedSelectOptionPayload")]
  InsertOrUpdateSelectOption = 32,

  #[event(input = "RepeatedSelectOptionPayload")]
  DeleteSelectOption = 33,

  #[event(input = "CreateRowPayloadPB", output = "RowMetaPB")]
  CreateRow = 50,

  /// [GetRow] event is used to get the row data,[RowPB]. [OptionalRowPB] is a wrapper that enables
  /// to return a nullable row data.
  #[event(input = "RowIdPB", output = "OptionalRowPB")]
  GetRow = 51,

  #[event(input = "RowIdPB")]
  DeleteRow = 52,

  #[event(input = "RowIdPB")]
  DuplicateRow = 53,

  #[event(input = "MoveRowPayloadPB")]
  MoveRow = 54,

  #[event(input = "RowIdPB", output = "RowMetaPB")]
  GetRowMeta = 55,

  #[event(input = "UpdateRowMetaChangesetPB")]
  UpdateRowMeta = 56,

  #[event(input = "CellIdPB", output = "CellPB")]
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

  /// [UpdateSelectOptionCell] event is used to update a select option cell's data. [SelectOptionCellChangesetPB]
  /// contains options that will be deleted or inserted. It can be cast to [CellChangesetPB] that
  /// will be used by the `update_cell` function.
  #[event(input = "SelectOptionCellChangesetPB")]
  UpdateSelectOptionCell = 72,

  #[event(input = "CellIdPB", output = "ChecklistCellDataPB")]
  GetChecklistCellData = 73,

  #[event(input = "ChecklistCellDataChangesetPB")]
  UpdateChecklistCell = 74,

  /// [UpdateDateCell] event is used to update a date cell's data. [DateChangesetPB]
  /// contains the date and the time string. It can be cast to [CellChangesetPB] that
  /// will be used by the `update_cell` function.
  #[event(input = "DateChangesetPB")]
  UpdateDateCell = 80,

  #[event(input = "DatabaseViewIdPB", output = "RepeatedGroupPB")]
  GetGroups = 100,

  #[event(input = "DatabaseGroupIdPB", output = "GroupPB")]
  GetGroup = 101,

  #[event(input = "MoveGroupPayloadPB")]
  MoveGroup = 111,

  #[event(input = "MoveGroupRowPayloadPB")]
  MoveGroupRow = 112,

  #[event(input = "GroupByFieldPayloadPB")]
  SetGroupByField = 113,

  #[event(input = "UpdateGroupPB")]
  UpdateGroup = 114,

  /// Returns all the databases
  #[event(output = "RepeatedDatabaseDescriptionPB")]
  GetDatabases = 120,

  #[event(input = "LayoutSettingChangesetPB")]
  SetLayoutSetting = 121,

  #[event(input = "DatabaseLayoutMetaPB", output = "DatabaseLayoutSettingPB")]
  GetLayoutSetting = 122,

  #[event(input = "CalendarEventRequestPB", output = "RepeatedCalendarEventPB")]
  GetAllCalendarEvents = 123,

  #[event(
    input = "CalendarEventRequestPB",
    output = "RepeatedNoDateCalendarEventPB"
  )]
  GetNoDateCalendarEvents = 124,

  #[event(input = "RowIdPB", output = "CalendarEventPB")]
  GetCalendarEvent = 125,

  #[event(input = "MoveCalendarEventPB")]
  MoveCalendarEvent = 126,

  #[event(input = "CreateDatabaseViewPayloadPB")]
  CreateDatabaseView = 130,

  #[event(input = "DatabaseViewIdPB", output = "DatabaseExportDataPB")]
  ExportCSV = 141,
}
