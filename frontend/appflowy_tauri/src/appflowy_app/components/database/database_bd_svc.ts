import { Database } from '$app/interfaces/database';
import {
  DatabaseDescriptionPB,
  DatabasePB,
  DatabaseViewIdPB,
  DatabaseViewSettingPB,
  DatabaseLayoutPB,
  CreateDatabaseViewPayloadPB,
  DatabaseLayoutMetaPB,
  LayoutSettingChangesetPB,
  GroupPB,
  DatabaseGroupIdPB,
  GroupByFieldPayloadPB,
  UpdateGroupPB,
  MoveGroupPayloadPB,
  FieldPB,
  GetFieldPayloadPB,
  RepeatedFieldIdPB,
  DuplicateFieldPayloadPB,
  FieldChangesetPB,
  FieldType,
  UpdateFieldTypePayloadPB,
  MoveFieldPayloadPB,
  DeleteFieldPayloadPB,
  TypeOptionPB,
  TypeOptionPathPB,
  CreateFieldPayloadPB,
  TypeOptionChangesetPB,
  SelectOptionPB,
  CreateSelectOptionPayloadPB,
  RepeatedSelectOptionPayload,
  RowIdPB,
  RowMetaPB,
  CreateRowPayloadPB,
  MoveGroupRowPayloadPB,
  UpdateRowMetaChangesetPB,
  CellPB,
  CellIdPB,
  CellChangesetPB,
  SelectOptionCellDataPB,
  SelectOptionCellChangesetPB,
  ChecklistCellDataPB,
  ChecklistCellDataChangesetPB,
  DateChangesetPB,
  DatabaseLayoutSettingPB,
  RowPB,
  DatabaseExportDataPB,
  DatabaseSnapshotPB,
  FilterPB,
  SortPB,
  MoveRowPayloadPB,
} from '@/services/backend';
import {
  DatabaseEventGetDatabases,
  DatabaseEventGetDatabase,
  DatabaseEventGetDatabaseSetting,
  DatabaseEventCreateDatabaseView,
  DatabaseEventGetLayoutSetting,
  DatabaseEventSetLayoutSetting,
  DatabaseEventGetGroups,
  DatabaseEventGetGroup,
  DatabaseEventSetGroupByField,
  DatabaseEventUpdateGroup,
  DatabaseEventMoveGroup,
  DatabaseEventGetFields,
  DatabaseEventGetPrimaryField,
  DatabaseEventDuplicateField,
  DatabaseEventUpdateField,
  DatabaseEventUpdateFieldType,
  DatabaseEventMoveField,
  DatabaseEventDeleteField,
  DatabaseEventGetTypeOption,
  DatabaseEventCreateTypeOption,
  DatabaseEventUpdateFieldTypeOption,
  DatabaseEventCreateSelectOption,
  DatabaseEventInsertOrUpdateSelectOption,
  DatabaseEventDeleteSelectOption,
  DatabaseEventGetRow,
  DatabaseEventCreateRow,
  DatabaseEventDuplicateRow,
  DatabaseEventDeleteRow,
  DatabaseEventMoveGroupRow,
  DatabaseEventGetRowMeta,
  DatabaseEventUpdateRowMeta,
  DatabaseEventGetCell,
  DatabaseEventUpdateCell,
  DatabaseEventGetSelectOptionCellData,
  DatabaseEventUpdateSelectOptionCell,
  DatabaseEventGetChecklistCellData,
  DatabaseEventUpdateChecklistCell,
  DatabaseEventUpdateDateCell,
  DatabaseEventExportCSV,
  DatabaseEventGetDatabaseSnapshots,
  DatabaseEventGetAllFilters,
  DatabaseEventGetAllSorts,
  DatabaseEventMoveRow,
} from "@/services/backend/events/flowy-database2";

export async function getDatabases(): Promise<DatabaseDescriptionPB[]> {
  const result = await DatabaseEventGetDatabases();

  return result.map(value => value.items).unwrap();
}

export async function getDatabase(viewId: string): Promise<DatabasePB> {
  const payload = DatabaseViewIdPB.fromObject({
    value: viewId,
  });

  const result = await DatabaseEventGetDatabase(payload);

  return result.unwrap();
}

export async function getDatabaseSetting(viewId: string): Promise<DatabaseViewSettingPB> {
  const payload = DatabaseViewIdPB.fromObject({
    value: viewId,
  });

  const result = await DatabaseEventGetDatabaseSetting(payload);

  return result.unwrap();
}

export async function createDatabaseView(
  viewId: string,
  data?: {
    name?: string;
    layout?: DatabaseLayoutPB;
  },
): Promise<void> {
  const payload = CreateDatabaseViewPayloadPB.fromObject({
    view_id: viewId,
    name: data?.name,
    layout_type: data?.layout,
  });

  const result = await DatabaseEventCreateDatabaseView(payload);

  return result.unwrap();
}

export async function getLayoutSetting(viewId: string, layout: DatabaseLayoutPB): Promise<DatabaseLayoutSettingPB> {
  const payload = DatabaseLayoutMetaPB.fromObject({
    view_id: viewId,
    layout: layout,
  });

  const result = await DatabaseEventGetLayoutSetting(payload);

  return result.unwrap();
}

export async function setLayoutSetting(viewId: string, setting: {
  layoutType?: DatabaseLayoutPB;
  calendar?: Database.CalendarLayoutSetting;
}): Promise<void> {
  const payload = LayoutSettingChangesetPB.fromObject({
    view_id: viewId,
    layout_type: setting.layoutType,
    calendar: setting.calendar ? {
      field_id: setting.calendar.fieldId,
      layout_ty: setting.calendar.layoutTy,
      first_day_of_week: setting.calendar.firstDayOfWeek,
      show_weekends: setting.calendar.showWeekends,
      show_week_numbers: setting.calendar.showWeekNumbers,
    } : undefined,
  });

  const result = await DatabaseEventSetLayoutSetting(payload);

  return result.unwrap();
}

export async function getGroups(viewId: string): Promise<GroupPB[]> {
  const payload = DatabaseViewIdPB.fromObject({
    value: viewId,
  });

  const result = await DatabaseEventGetGroups(payload);

  return result.map(value => value.items).unwrap();
}

export async function getGroup(viewId: string, groupId: string): Promise<GroupPB> {
  const payload = DatabaseGroupIdPB.fromObject({
    view_id: viewId,
    group_id: groupId,
  });

  const result = await DatabaseEventGetGroup(payload);

  return result.unwrap();
}

export async function setGroupByField(viewId: string, fieldId: string): Promise<void> {
  const payload = GroupByFieldPayloadPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
  });

  const result = await DatabaseEventSetGroupByField(payload);

  return result.unwrap();
}

export async function updateGroup(
  viewId: string,
  groupId: string,
  data: {
    name?: string;
    visible?: boolean;
  },
): Promise<void> {
  const payload = UpdateGroupPB.fromObject({
    view_id: viewId,
    group_id: groupId,
    name: data.name,
    visible: data.visible,
  });

  const result = await DatabaseEventUpdateGroup(payload);

  return result.unwrap();
}

export async function moveGroup(viewId: string, fromGroupId: string, toGroupId: string): Promise<void> {
  const payload = MoveGroupPayloadPB.fromObject({
    view_id: viewId,
    from_group_id: fromGroupId,
    to_group_id: toGroupId,
  });

  const result = await DatabaseEventMoveGroup(payload);

  return result.unwrap();
}


export async function getFilters(viewId: string): Promise<FilterPB[]> {
  const payload = DatabaseViewIdPB.fromObject({
    value: viewId,
  });

  const result = await DatabaseEventGetAllFilters(payload);

  return result.map(value => value.items).unwrap();
}


export async function getSorts(viewId: string): Promise<SortPB[]> {
  const payload = DatabaseViewIdPB.fromObject({
    value: viewId,
  });

  const result = await DatabaseEventGetAllSorts(payload);

  return result.map(value => value.items).unwrap();
}


export async function getFields(viewId: string, fieldIds?: string[]): Promise<FieldPB[]> {
  const payload = GetFieldPayloadPB.fromObject({
    view_id: viewId,
    field_ids: fieldIds ? RepeatedFieldIdPB.fromObject({
      items: fieldIds.map(fieldId => ({ field_id: fieldId })),
    }) : undefined,
  });

  const result = await DatabaseEventGetFields(payload);

  return result.map((value) => value.items).unwrap();
}

export async function getPrimaryField(viewId: string): Promise<FieldPB> {
  const payload = DatabaseViewIdPB.fromObject({
    value: viewId,
  });

  const result = await DatabaseEventGetPrimaryField(payload);

  return result.unwrap();
}

export async function duplicateField(viewId: string, fieldId: string): Promise<void> {
  const payload = DuplicateFieldPayloadPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
  });

  const result = await DatabaseEventDuplicateField(payload);

  return result.unwrap();
}

export async function updateField(viewId: string, fieldId: string, data: {
  name?: string;
  desc?: string;
  frozen?: boolean;
  visibility?: boolean;
  width?: number;
}): Promise<void> {
  const payload = FieldChangesetPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
    ...data,
  });

  const result = await DatabaseEventUpdateField(payload);

  return result.unwrap();
}

export async function updateFieldType(viewId: string, fieldId: string, fieldType: FieldType): Promise<void> {
  const payload = UpdateFieldTypePayloadPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
    field_type: fieldType,
  });

  const result = await DatabaseEventUpdateFieldType(payload);

  return result.unwrap();
}

export async function moveField(viewId: string, fieldId: string, fromIndex: number, toIndex: number): Promise<void> {
  const payload = MoveFieldPayloadPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
    from_index: fromIndex,
    to_index: toIndex,
  });

  const result = await DatabaseEventMoveField(payload);

  return result.unwrap();
}

export async function deleteField(viewId: string, fieldId: string): Promise<void> {
  const payload = DeleteFieldPayloadPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
  });

  const result = await DatabaseEventDeleteField(payload);

  return result.unwrap();
}


export async function getFieldTypeOption(viewId: string, fieldId: string, fieldType?: FieldType): Promise<TypeOptionPB> {
  const payload = TypeOptionPathPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
    field_type: fieldType,
  });

  const result = await DatabaseEventGetTypeOption(payload);

  return result.unwrap();
}

/**
 * TODO data type need to clarify
 */
export async function createFieldTypeOption(viewId: string, fieldType: FieldType, data?: Uint8Array): Promise<TypeOptionPB> {
  const payload = CreateFieldPayloadPB.fromObject({
    view_id: viewId,
    field_type: fieldType,
    type_option_data: data,
  });

  const result = await DatabaseEventCreateTypeOption(payload);

  return result.unwrap();
}

/**
 * TODO data type need to clarify
 */
export async function updateFieldTypeOption(viewId: string, fieldId: string, data: Uint8Array): Promise<void> {
  const payload = TypeOptionChangesetPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
    type_option_data: data,
  });

  const result = await DatabaseEventUpdateFieldTypeOption(payload);

  return result.unwrap();
}

export async function createSelectOption(viewId: string, fieldId: string, optionName: string): Promise<SelectOptionPB> {
  const payload = CreateSelectOptionPayloadPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
    option_name: optionName,
  });

  const result = await DatabaseEventCreateSelectOption(payload);

  return result.unwrap();
}

/**
 * @param [rowId] If pass the rowId, the cell will select this option after insert or update.
 */
export async function insertOrUpdateSelectOption(
  viewId: string,
  fieldId: string,
  items: Partial<Database.SelectOption>[],
  rowId?: string,
): Promise<void> {
  const payload = RepeatedSelectOptionPayload.fromObject({
    view_id: viewId,
    field_id: fieldId,
    row_id: rowId,
    items: items,
  });

  const result = await DatabaseEventInsertOrUpdateSelectOption(payload);

  return result.unwrap();
}

export async function deleteSelectOption(
  viewId: string,
  fieldId: string,
  items: Partial<Database.SelectOption>[],
  rowId?: string,
): Promise<void> {
  const payload = RepeatedSelectOptionPayload.fromObject({
    view_id: viewId,
    field_id: fieldId,
    row_id: rowId,
    items: items,
  });

  const result = await DatabaseEventDeleteSelectOption(payload);

  return result.unwrap();
}


export async function getRow(viewId: string, rowId: string, groupId?: string): Promise<RowPB | undefined> {
  const payload = RowIdPB.fromObject({
    view_id: viewId,
    row_id: rowId,
    group_id: groupId,
  });

  const result = await DatabaseEventGetRow(payload);

  return result.map(value => value.row).unwrap();
}

export async function createRow(viewId: string, params?: {
  startRowId?: string;
  groupId?: string;
  data?: Record<string, string>;
}): Promise<RowMetaPB> {
  const payload = CreateRowPayloadPB.fromObject({
    view_id: viewId,
    start_row_id: params?.startRowId,
    group_id: params?.groupId,
    data: params?.data ? { cell_data_by_field_id: params.data } : undefined,
  });

  const result = await DatabaseEventCreateRow(payload);

  return result.unwrap();
}

export async function duplicateRow(viewId: string, rowId: string, groupId?: string): Promise<void> {
  const payload = RowIdPB.fromObject({
    view_id: viewId,
    row_id: rowId,
    group_id: groupId,
  });

  const result = await DatabaseEventDuplicateRow(payload);

  return result.unwrap();
}

export async function deleteRow(viewId: string, rowId: string, groupId?: string): Promise<void> {
  const payload = RowIdPB.fromObject({
    view_id: viewId,
    row_id: rowId,
    group_id: groupId,
  });

  const result = await DatabaseEventDeleteRow(payload);

  return result.unwrap();
}

export async function moveRow(viewId: string, fromRowId: string, toRowId: string): Promise<void> {
  const payload = MoveRowPayloadPB.fromObject({
    view_id: viewId,
    from_row_id: fromRowId,
    to_row_id: toRowId,
  });

  const result = await DatabaseEventMoveRow(payload);

  return result.unwrap();
}

/**
 * Move the row from one group to another group
 *
 * @param fromRowId
 * @param toGroupId
 * @param toRowId used to locate the moving row location.
 * @returns
 */
export async function moveGroupRow(viewId: string, fromRowId: string, toGroupId: string, toRowId?: string): Promise<void> {
  const payload = MoveGroupRowPayloadPB.fromObject({
    view_id: viewId,
    from_row_id: fromRowId,
    to_group_id: toGroupId,
    to_row_id: toRowId,
  });

  const result = await DatabaseEventMoveGroupRow(payload);

  return result.unwrap();
}


export async function getRowMeta(viewId: string, rowId: string, groupId?: string): Promise<RowMetaPB> {
  const payload = RowIdPB.fromObject({
    view_id: viewId,
    row_id: rowId,
    group_id: groupId,
  });

  const result = await DatabaseEventGetRowMeta(payload);

  return result.unwrap();
}

export async function updateRowMeta(
  viewId: string,
  rowId: string,
  meta: {
    iconUrl?: string;
    coverUrl?: string;
  },
): Promise<void> {
  const payload = UpdateRowMetaChangesetPB.fromObject({
    view_id: viewId,
    id: rowId,
    icon_url: meta.iconUrl,
    cover_url: meta.coverUrl,
  });

  const result = await DatabaseEventUpdateRowMeta(payload);

  return result.unwrap();
}


export async function getCell(viewId: string, rowId: string, fieldId: string): Promise<CellPB> {
  const payload = CellIdPB.fromObject({
    view_id: viewId,
    row_id: rowId,
    field_id: fieldId,
  });

  const result = await DatabaseEventGetCell(payload);

  return result.unwrap();
}

export async function updateCell(viewId: string, rowId: string, fieldId: string, changeset: string): Promise<void> {
  const payload = CellChangesetPB.fromObject({
    view_id: viewId,
    row_id: rowId,
    field_id: fieldId,
    cell_changeset: changeset,
  });

  const result = await DatabaseEventUpdateCell(payload);

  return result.unwrap();
}

export async function getSelectOptionCell(viewId: string, rowId: string, fieldId: string): Promise<SelectOptionCellDataPB> {
  const payload = CellIdPB.fromObject({
    view_id: viewId,
    row_id: rowId,
    field_id: fieldId,
  });

  const result = await DatabaseEventGetSelectOptionCellData(payload);

  return result.unwrap();
}

export async function updateSelectOptionCell(
  viewId: string,
  rowId: string,
  fieldId: string,
  data: {
    insertOptionIds?: string[];
    deleteOptionIds?: string[];
  },
): Promise<void> {
  const payload = SelectOptionCellChangesetPB.fromObject({
    cell_identifier: {
      view_id: viewId,
      row_id: rowId,
      field_id: fieldId,
    },
    insert_option_ids: data.insertOptionIds,
    delete_option_ids: data.deleteOptionIds,
  });

  const result = await DatabaseEventUpdateSelectOptionCell(payload);

  return result.unwrap();
}

export async function getChecklistCell(viewId: string, rowId: string, fieldId: string): Promise<ChecklistCellDataPB> {
  const payload = CellIdPB.fromObject({
    view_id: viewId,
    row_id: rowId,
    field_id: fieldId,
  });

  const result = await DatabaseEventGetChecklistCellData(payload);

  return result.unwrap();
}

export async function updateChecklistCell(
  viewId: string,
  rowId: string,
  fieldId: string,
  data: {
    insertOptions?: string[];
    selectedOptionIds?: string[];
    deleteOptionIds?: string[];
    updateOptions?: Partial<Database.SelectOption>[];
  },
): Promise<void> {
  const payload = ChecklistCellDataChangesetPB.fromObject({
    view_id: viewId,
    row_id: rowId,
    field_id: fieldId,
    insert_options: data.insertOptions,
    selected_option_ids: data.selectedOptionIds,
    delete_option_ids: data.deleteOptionIds,
    update_options: data.updateOptions,
  });

  const result = await DatabaseEventUpdateChecklistCell(payload);

  return result.unwrap();
}

export async function updateDateCell(
  viewId: string,
  rowId: string,
  fieldId: string,
  data: {
    date?: number;
    time?: string;
    includeTime?: boolean;
    clearFlag?: boolean;
  },
): Promise<void> {
  const payload = DateChangesetPB.fromObject({
    cell_id: {
      view_id: viewId,
      row_id: rowId,
      field_id: fieldId,
    },
    date: data.date,
    time: data.time,
    include_time: data.includeTime,
    clear_flag: data.clearFlag,
  });

  const result = await DatabaseEventUpdateDateCell(payload);

  return result.unwrap();
}


export async function exportCSV(viewId: string): Promise<DatabaseExportDataPB> {
  const payload = DatabaseViewIdPB.fromObject({
    value: viewId,
  });

  const result = await DatabaseEventExportCSV(payload);

  return result.unwrap();
}

export async function getDatabaseSnapshots(viewId: string): Promise<DatabaseSnapshotPB[]> {
  const payload = DatabaseViewIdPB.fromObject({
    value: viewId,
  });

  const result = await DatabaseEventGetDatabaseSnapshots(payload);

  return result.map(value => value.items).unwrap();
}
