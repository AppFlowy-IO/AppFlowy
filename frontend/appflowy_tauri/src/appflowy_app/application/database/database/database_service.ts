import { DatabaseViewIdPB } from '@/services/backend';
import {
  DatabaseEventGetDatabase,
  DatabaseEventGetDatabaseId,
  DatabaseEventGetDatabaseSetting,
} from '@/services/backend/events/flowy-database2';
import { fieldService } from '../field';
import { pbToFilter } from '../filter';
import { groupService, pbToGroupSetting } from '../group';
import { pbToRowMeta } from '../row';
import { pbToSort } from '../sort';
import { Database } from './database_types';

export async function getDatabaseId(viewId: string): Promise<string> {
  const payload = DatabaseViewIdPB.fromObject({ value: viewId });

  const result = await DatabaseEventGetDatabaseId(payload);

  return result.map((value) => value.value).unwrap();
}

export async function getDatabase(viewId: string) {
  const payload = DatabaseViewIdPB.fromObject({
    value: viewId,
  });

  const result = await DatabaseEventGetDatabase(payload);

  if (!result.ok) return Promise.reject('Failed to get database');

  return result
    .map((value) => {
      return {
        id: value.id,
        isLinked: value.is_linked,
        layoutType: value.layout_type,
        fieldIds: value.fields.map((field) => field.field_id),
        rowMetas: value.rows.map(pbToRowMeta),
      };
    })
    .unwrap();
}

export async function getDatabaseSetting(viewId: string) {
  const payload = DatabaseViewIdPB.fromObject({
    value: viewId,
  });

  const result = await DatabaseEventGetDatabaseSetting(payload);

  return result
    .map((value) => {
      return {
        filters: value.filters.items.map(pbToFilter),
        sorts: value.sorts.items.map(pbToSort),
        groupSettings: value.group_settings.items.map(pbToGroupSetting),
      };
    })
    .unwrap();
}

export async function openDatabase(viewId: string): Promise<Database> {
  const { id, isLinked, layoutType, fieldIds, rowMetas } = await getDatabase(viewId);

  const { filters, sorts, groupSettings } = await getDatabaseSetting(viewId);

  const { fields, typeOptions } = await fieldService.getFields(viewId, fieldIds);

  const groups = await groupService.getGroups(viewId);

  return {
    id,
    isLinked,
    layoutType,
    fields,
    rowMetas,
    filters,
    sorts,
    groups,
    groupSettings,
    typeOptions,
    cells: {},
  };
}
