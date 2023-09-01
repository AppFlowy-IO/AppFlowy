import {
  DatabaseEventCreateRow,
  DatabaseEventDeleteRow,
  DatabaseEventDuplicateRow,
  DatabaseEventGetDatabase,
  DatabaseEventGetDatabaseSetting,
  DatabaseEventGetFields,
  DatabaseEventGetGroup,
  DatabaseEventGetGroups,
  DatabaseEventMoveField,
  DatabaseEventMoveGroup,
  DatabaseEventMoveGroupRow,
  DatabaseEventMoveRow,
  DatabaseEventUpdateField,
  DatabaseGroupIdPB,
  FieldChangesetPB,
  MoveFieldPayloadPB,
  MoveGroupPayloadPB,
  MoveGroupRowPayloadPB,
  MoveRowPayloadPB,
  RowIdPB,
  DatabaseEventUpdateDatabaseSetting,
  DuplicateFieldPayloadPB,
  DatabaseEventDuplicateField,
} from '@/services/backend/events/flowy-database2';
import {
  GetFieldPayloadPB,
  RepeatedFieldIdPB,
  FieldIdPB,
  DatabaseViewIdPB,
  CreateRowPayloadPB,
  ViewIdPB,
} from '@/services/backend';
import { FolderEventCloseView } from '@/services/backend/events/flowy-folder2';
import { TypeOptionController } from '$app/stores/effects/database/field/type_option/type_option_controller';
import { None } from 'ts-results';

/// A service that wraps the backend service
export class DatabaseBackendService {
  viewId: string;

  constructor(viewId: string) {
    this.viewId = viewId;
  }

  /// Open a database
  openDatabase = async () => {
    const payload = DatabaseViewIdPB.fromObject({
      value: this.viewId,
    });

    return DatabaseEventGetDatabase(payload);
  };

  /// Close a database
  closeDatabase = async () => {
    const payload = ViewIdPB.fromObject({ value: this.viewId });

    return FolderEventCloseView(payload);
  };

  /// Create a row in database
  /// 1.The row will be the last row in database if the params is undefined
  /// 2.The row will be placed after the passed-in rowId
  /// 3.The row will be moved to the group with groupId. Currently, grouping is
  /// only support in kanban board.
  createRow = async (params?: { rowId?: string; groupId?: string }) => {
    const payload = CreateRowPayloadPB.fromObject({ view_id: this.viewId });

    if (params?.rowId !== undefined) {
      payload.start_row_id = params.rowId;
    }

    if (params?.groupId !== undefined) {
      payload.group_id = params.groupId;
    }

    return DatabaseEventCreateRow(payload);
  };

  duplicateRow = async (rowId: string) => {
    const payload = RowIdPB.fromObject({ view_id: this.viewId, row_id: rowId });

    return DatabaseEventDuplicateRow(payload);
  };

  deleteRow = async (rowId: string) => {
    const payload = RowIdPB.fromObject({ view_id: this.viewId, row_id: rowId });

    return DatabaseEventDeleteRow(payload);
  };

  moveRow = async (fromRowId: string, toRowId: string) => {
    const payload = MoveRowPayloadPB.fromObject({ view_id: this.viewId, from_row_id: fromRowId, to_row_id: toRowId });
    return DatabaseEventMoveRow(payload);
  };

  /// Move the row from one group to another group
  /// [toRowId] is used to locate the moving row location.
  moveGroupRow = (fromRowId: string, toGroupId: string, toRowId?: string) => {
    const payload = MoveGroupRowPayloadPB.fromObject({
      view_id: this.viewId,
      from_row_id: fromRowId,
      to_group_id: toGroupId,
    });

    if (toRowId !== undefined) {
      payload.to_row_id = toRowId;
    }

    return DatabaseEventMoveGroupRow(payload);
  };

  moveGroup = (fromGroupId: string, toGroupId: string) => {
    const payload = MoveGroupPayloadPB.fromObject({
      view_id: this.viewId,
      from_group_id: fromGroupId,
      to_group_id: toGroupId,
    });

    return DatabaseEventMoveGroup(payload);
  };

  /// Get all fields in database
  getFields = async (fieldIds?: FieldIdPB[]) => {
    const payload = GetFieldPayloadPB.fromObject({ view_id: this.viewId });

    if (!fieldIds) {
      payload.field_ids = RepeatedFieldIdPB.fromObject({ items: fieldIds });
    }

    return DatabaseEventGetFields(payload).then((result) => result.map((value) => value.items));
  };

  /// Get a group by id
  getGroup = (groupId: string) => {
    const payload = DatabaseGroupIdPB.fromObject({ view_id: this.viewId, group_id: groupId });

    return DatabaseEventGetGroup(payload);
  };

  moveField = (params: { fieldId: string; fromIndex: number; toIndex: number }) => {
    const payload = MoveFieldPayloadPB.fromObject({
      view_id: this.viewId,
      field_id: params.fieldId,
      from_index: params.fromIndex,
      to_index: params.toIndex,
    });

    return DatabaseEventMoveField(payload);
  };

  changeWidth = (params: { fieldId: string; width: number }) => {
    const payload = FieldChangesetPB.fromObject({ view_id: this.viewId, field_id: params.fieldId, width: params.width });

    return DatabaseEventUpdateField(payload);
  };

  duplicateField = (fieldId: string) => {
    const payload = DuplicateFieldPayloadPB.fromObject({ view_id: this.viewId, field_id: fieldId });

    return DatabaseEventDuplicateField(payload);
  };

  createField = async () => {
    const fieldController = new TypeOptionController(this.viewId, None);

    await fieldController.initialize();
  };

  /// Get all groups in database
  /// It should only call once after the board open
  loadGroups = () => {
    const payload = DatabaseViewIdPB.fromObject({ value: this.viewId });

    return DatabaseEventGetGroups(payload);
  };

  getSettings = () => {
    const payload = DatabaseViewIdPB.fromObject({ value: this.viewId });

    return DatabaseEventGetDatabaseSetting(payload);
  };
}
