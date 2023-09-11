import { useContext, useEffect, useMemo } from 'react';
import { proxy, useSnapshot } from 'valtio';
import { useParams } from 'react-router-dom';
import { DatabaseLayoutPB, DatabaseNotification } from '@/services/backend';
import { type Database, fieldPbToField } from '$app/interfaces/database';
import { subscribeNotifications } from '$app/hooks';
import { DatabaseContext } from './database.context';
import * as service from './database_bd_svc';

export const useDatabase = () => useSnapshot(useContext(DatabaseContext));
export const useViewId = () => useParams().id!;

const fetchDatabase = async (viewId: string) => {
  const [
    databasePb,
    settingPb,
  ] = await Promise.all([
    service.getDatabase(viewId),
    service.getDatabaseSetting(viewId),
  ]);

  const fieldsPb = await service.getFields(viewId, databasePb.fields.map(field => field.field_id));

  const database: Database = {
    id: databasePb.id,
    viewId: viewId,
    name: '',
    layoutType: databasePb.layout_type,
    layoutSetting: {},
    isLinked: databasePb.is_linked,
    fields: fieldsPb.map(fieldPbToField),
    rows: databasePb.rows.map(row => ({
      id: row.id,
      documentId: row.document_id,
      icon: row.icon,
      cover: row.cover,
    })),
  };

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

  return database;
};

export const useConnectDatabase = (viewId: string) => {
  const database = useMemo(() => {
    const proxyDatabase = proxy<Database>({
      id: '',
      viewId,
      name: '',
      isLinked: false,
      layoutType: DatabaseLayoutPB.Grid,
      layoutSetting: {},
      rows: [],
      fields: [],
    });

    void fetchDatabase(viewId).then(value => Object.assign(proxyDatabase, value));

    return proxyDatabase;
  }, [viewId]);

  useEffect(() => {
    const unsubscribePromise = subscribeNotifications({
      [DatabaseNotification.DidUpdateFields]: async (result) => {
        if (result.err) {
          return;
        }
  
        const { fields: fieldIds } = await service.getDatabase(viewId);
        const newFieldsPb = await service.getFields(viewId, fieldIds.map(field => field.field_id));
  
        database.fields = newFieldsPb.map(fieldPbToField);
      },
      [DatabaseNotification.DidUpdateViewRows]:async (result) => {
        if (result.err) {
          return;
        }

        const {
          deleted_rows: deletedRowIds,
          inserted_rows: insertedRows,
          // TODO: updated_rows: updatedRows,
        } = result.val;

        deletedRowIds.forEach(rowId => {
          const index = database.rows.findIndex(row => row.id === rowId);

          if (index !== -1) {
            database.rows.splice(index, 1);
          }
        });

        insertedRows.forEach(({ index, row_meta: rowMeta }) => {
          database.rows.splice(index, 0, {
            id: rowMeta.id,
            documentId: rowMeta.document_id,
            cover: rowMeta.cover,
            icon: rowMeta.icon,
          });
        });
      }
    }, { id: viewId });

    return () => void unsubscribePromise.then(unsubscribe => unsubscribe());
  }, [viewId, database]);

  return database;
};
