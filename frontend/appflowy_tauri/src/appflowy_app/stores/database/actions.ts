import { type Database, fieldPbToField } from '$app/interfaces/database';
import { subscribeNotification } from '$app/hooks';
import { DatabaseLayoutPB, DatabaseNotification } from '@/services/backend';
import * as service from './bd_svc';
import { database } from './state';

export const readDatabase = async (viewId: string) => {
  const [
    databasePb,
    settingPb,
  ] = await Promise.all([
    service.getDatabase(viewId),
    service.getDatabaseSetting(viewId),
  ]);

  const fieldsPb = await service.getFields(viewId, databasePb.fields.map(field => field.field_id));

  const fields: Database.Field[] = fieldsPb.map(fieldPbToField);

  database.id = databasePb.id;
  database.viewId = viewId;
  database.layoutType = databasePb.layout_type;
  database.isLinked = databasePb.is_linked;
  database.fields = fields;
  database.rows = databasePb.rows.map(row => ({
    id: row.id,
    icon: row.icon,
    cover: row.cover,
  }));

  if (settingPb.layout_type === DatabaseLayoutPB.Grid) {
    const layoutSetting: Database.GridLayoutSetting = {};

    if (settingPb.has_filters) {
      layoutSetting.filters = settingPb.filters.items.map(filter => ({
        id: filter.id,
        fieldId: filter.field_id,
        fieldType: filter.field_type,
        data: filter.data,
      }));
    }

    if (settingPb.has_sorts) {
      layoutSetting.sorts = settingPb.sorts.items.map(sort => ({
        id: sort.id,
        fieldId: sort.field_id,
        fieldType: sort.field_type,
        condition: sort.condition,
      }));
    }

    if (settingPb.has_group_settings) {
      layoutSetting.groups = settingPb.group_settings.items.map(group => ({
        id: group.id,
        fieldId: group.field_id,
      }));
    }

    database.layoutSetting = layoutSetting;
  }

  const unsubscribes = await Promise.all([
    subscribeNotification(viewId, DatabaseNotification.DidUpdateFields, async data => {
      if (data.err) {
        return;
      }

      const { fields: fieldIds } = await service.getDatabase(viewId);
      const newFieldsPb = await service.getFields(viewId, fieldIds.map(field => field.field_id));
      
      database.fields = newFieldsPb.map(fieldPbToField);
    }),
  ]);

  return () => {
    unsubscribes.forEach(unsubscribe => unsubscribe());
  };
};
