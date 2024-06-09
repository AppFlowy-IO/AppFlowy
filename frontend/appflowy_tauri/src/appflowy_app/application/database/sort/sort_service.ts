import {
  DatabaseViewIdPB,
  DatabaseSettingChangesetPB,
} from '@/services/backend';
import {
  DatabaseEventDeleteAllSorts,
  DatabaseEventGetAllSorts, DatabaseEventUpdateDatabaseSetting,
} from '@/services/backend/events/flowy-database2';
import { pbToSort, Sort } from './sort_types';

export async function getAllSorts(viewId: string): Promise<Sort[]> {
  const payload = DatabaseViewIdPB.fromObject({
    value: viewId,
  });

  const result = await DatabaseEventGetAllSorts(payload);

  return result.map(value => value.items.map(pbToSort)).unwrap();
}

export async function insertSort(viewId: string, sort: Omit<Sort, 'id'>): Promise<void> {
  const payload = DatabaseSettingChangesetPB.fromObject({
    view_id: viewId,
    update_sort: {
      view_id: viewId,
      field_id: sort.fieldId,
      condition: sort.condition,
    },
  });

  const result = await DatabaseEventUpdateDatabaseSetting(payload);

  return result.unwrap();
}

export async function updateSort(viewId: string, sort: Sort): Promise<void> {
  const payload = DatabaseSettingChangesetPB.fromObject({
    view_id: viewId,
    update_sort: {
      view_id: viewId,
      sort_id: sort.id,
      field_id: sort.fieldId,
      condition: sort.condition,
    },
  });

  const result = await DatabaseEventUpdateDatabaseSetting(payload);

  return result.unwrap();
}

export async function deleteSort(viewId: string, sort: Sort): Promise<void> {
  const payload = DatabaseSettingChangesetPB.fromObject({
    view_id: viewId,
    delete_sort: {
      view_id: viewId,
      sort_id: sort.id,
    },
  });

  const result = await DatabaseEventUpdateDatabaseSetting(payload);

  return result.unwrap();
}

export async function deleteAllSorts(viewId: string): Promise<void> {
  const payload = DatabaseViewIdPB.fromObject({
    value: viewId,
  });
  const result = await DatabaseEventDeleteAllSorts(payload);

  return result.unwrap();
}
