import {
  CreateBoardCardPayloadPB,
  DatabaseEventCreateBoardCard,
  DatabaseEventCreateRow,
  DatabaseEventGetDatabase,
  DatabaseEventGetFields,
  DatabaseEventGetGroup,
  DatabaseEventGetGroups,
  DatabaseEventMoveGroup,
  DatabaseEventMoveGroupRow,
  DatabaseGroupIdPB,
  MoveGroupPayloadPB,
  MoveGroupRowPayloadPB,
} from '../../../../services/backend/events/flowy-database';
import {
  GetFieldPayloadPB,
  RepeatedFieldIdPB,
  FieldIdPB,
  DatabaseViewIdPB,
  CreateRowPayloadPB,
  ViewIdPB,
} from '../../../../services/backend';
import { FolderEventCloseView } from '../../../../services/backend/events/flowy-folder';

export class DatabaseBackendService {
  viewId: string;

  constructor(viewId: string) {
    this.viewId = viewId;
  }

  openDatabase = async () => {
    const payload = DatabaseViewIdPB.fromObject({
      value: this.viewId,
    });
    return DatabaseEventGetDatabase(payload);
  };

  closeDatabase = async () => {
    const payload = ViewIdPB.fromObject({ value: this.viewId });
    return FolderEventCloseView(payload);
  };

  createRow = async (rowId?: string) => {
    const payload = CreateRowPayloadPB.fromObject({ view_id: this.viewId, start_row_id: rowId ?? undefined });
    return DatabaseEventCreateRow(payload);
  };

  createGroupRow = async (groupId: string, startRowId?: string) => {
    const payload = CreateBoardCardPayloadPB.fromObject({ view_id: this.viewId, group_id: groupId });
    if (startRowId !== undefined) {
      payload.start_row_id = startRowId;
    }
    return DatabaseEventCreateBoardCard(payload);
  };

  moveRow = (rowId: string, groupId?: string) => {
    const payload = MoveGroupRowPayloadPB.fromObject({ view_id: this.viewId, from_row_id: rowId });
    if (groupId !== undefined) {
      payload.to_group_id = groupId;
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

  getFields = async (fieldIds?: FieldIdPB[]) => {
    const payload = GetFieldPayloadPB.fromObject({ view_id: this.viewId });

    if (!fieldIds) {
      payload.field_ids = RepeatedFieldIdPB.fromObject({ items: fieldIds });
    }

    return DatabaseEventGetFields(payload).then((result) => result.map((value) => value.items));
  };

  getGroup = (groupId: string) => {
    const payload = DatabaseGroupIdPB.fromObject({ view_id: this.viewId, group_id: groupId });
    return DatabaseEventGetGroup(payload);
  };

  loadGroups = () => {
    const payload = DatabaseViewIdPB.fromObject({ value: this.viewId });
    return DatabaseEventGetGroups(payload);
  };
}
