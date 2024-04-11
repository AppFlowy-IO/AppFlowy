import {
  CreateRowPayloadPB,
  MoveGroupRowPayloadPB,
  MoveRowPayloadPB,
  OrderObjectPositionTypePB,
  RowIdPB,
  UpdateRowMetaChangesetPB,
} from '@/services/backend';
import {
  DatabaseEventCreateRow,
  DatabaseEventDeleteRow,
  DatabaseEventDuplicateRow,
  DatabaseEventGetRowMeta,
  DatabaseEventMoveGroupRow,
  DatabaseEventMoveRow,
  DatabaseEventUpdateRowMeta,
} from '@/services/backend/events/flowy-database2';
import { pbToRowMeta, RowMeta } from './row_types';

export async function createRow(viewId: string, params?: {
  position?: OrderObjectPositionTypePB;
  rowId?: string;
  groupId?: string;
  data?: Record<string, string>;
}): Promise<RowMeta> {
  const payload = CreateRowPayloadPB.fromObject({
    view_id: viewId,
    row_position: {
      position: params?.position,
      object_id: params?.rowId,
    },
    group_id: params?.groupId,
    data: params?.data,
  });

  const result = await DatabaseEventCreateRow(payload);

  return result.map(pbToRowMeta).unwrap();
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


export async function getRowMeta(viewId: string, rowId: string, groupId?: string): Promise<RowMeta> {
  const payload = RowIdPB.fromObject({
    view_id: viewId,
    row_id: rowId,
    group_id: groupId,
  });

  const result = await DatabaseEventGetRowMeta(payload);

  return result.map(pbToRowMeta).unwrap();
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
