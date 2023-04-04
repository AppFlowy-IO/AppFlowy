import {
  DatabaseEventCreateRow,
  DatabaseEventGetDatabase,
  DatabaseEventGetDatabaseSetting,
  DatabaseEventGetFields,
  DatabaseEventGetGroup,
  DatabaseEventGetGroups,
  DatabaseEventMoveField,
  DatabaseEventMoveGroup,
  DatabaseEventMoveGroupRow,
  DatabaseEventMoveRow,
  DatabaseGroupIdPB,
  MoveFieldPayloadPB,
  MoveGroupPayloadPB,
  MoveGroupRowPayloadPB,
  MoveRowPayloadPB,
} from '@/services/backend/events/flowy-database';
import {
  GetFieldPayloadPB,
  RepeatedFieldIdPB,
  FieldIdPB,
  DatabaseViewIdPB,
  CreateRowPayloadPB,
  ViewIdPB,
} from '@/services/backend';
import { FolderEventCloseView } from '@/services/backend/events/flowy-folder';

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

  /// Move the row from one group to another group
  /// [groupId] can be the moving row's group id or others.
  /// [toRowId] is used to locate the moving row location.
  moveGroupRow = (fromRowId: string, groupId: string, toRowId?: string) => {
    const payload = MoveGroupRowPayloadPB.fromObject({
      view_id: this.viewId,
      from_row_id: fromRowId,
      to_group_id: groupId,
    });
    if (toRowId !== undefined) {
      payload.to_row_id = toRowId;
    }

    return DatabaseEventMoveGroupRow(payload);
  };

  exchangeRow = (fromRowId: string, toRowId: string) => {
    const payload = MoveRowPayloadPB.fromObject({
      view_id: this.viewId,
      from_row_id: fromRowId,
      to_row_id: toRowId,
    });
    return DatabaseEventMoveRow(payload);
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
