import {
  DatabaseEventGetAllFilters,
  DatabaseEventUpdateDatabaseSetting,
  DatabaseSettingChangesetPB,
  DatabaseViewIdPB,
  FieldType,
  FilterPB,
} from '@/services/backend/events/flowy-database2';
import { Filter, filterDataToPB, UndeterminedFilter } from './filter_types';

export async function getAllFilters(viewId: string): Promise<FilterPB[]> {
  const payload = DatabaseViewIdPB.fromObject({ value: viewId });

  const result = await DatabaseEventGetAllFilters(payload);

  return result.map((value) => value.items).unwrap();
}

export async function insertFilter({
  viewId,
  fieldId,
  fieldType,
  data,
}: {
  viewId: string;
  fieldId: string;
  fieldType: FieldType;
  data?: UndeterminedFilter['data'];
}): Promise<void> {
  const payload = DatabaseSettingChangesetPB.fromObject({
    view_id: viewId,
    insert_filter: {
      data: {
        field_id: fieldId,
        field_type: fieldType,
        data: data ? filterDataToPB(data, fieldType)?.serialize() : undefined,
      },
    },
  });

  const result = await DatabaseEventUpdateDatabaseSetting(payload);

  if (!result.ok) {
    return Promise.reject(result.val);
  }

  return result.val;
}

export async function updateFilter(viewId: string, filter: UndeterminedFilter): Promise<void> {
  const payload = DatabaseSettingChangesetPB.fromObject({
    view_id: viewId,
    update_filter_data: {
      filter_id: filter.id,
      data: {
        field_id: filter.fieldId,
        field_type: filter.fieldType,
        data: filterDataToPB(filter.data, filter.fieldType)?.serialize(),
      },
    },
  });

  const result = await DatabaseEventUpdateDatabaseSetting(payload);

  if (!result.ok) {
    return Promise.reject(result.val);
  }

  return result.val;
}

export async function deleteFilter(viewId: string, filter: Omit<Filter, 'data'>): Promise<void> {
  const payload = DatabaseSettingChangesetPB.fromObject({
    view_id: viewId,
    delete_filter: {
      filter_id: filter.id,
      field_id: filter.fieldId,
    },
  });

  const result = await DatabaseEventUpdateDatabaseSetting(payload);

  if (!result.ok) {
    return Promise.reject(result.val);
  }

  return result.val;
}
