import { useEffect, useState } from 'react';
import { DatabaseController } from '../../../stores/effects/database/database_controller';
import { databaseActions, DatabaseFieldMap, IDatabaseColumn } from '../../../stores/reducers/database/slice';
import { useAppDispatch } from '../../../stores/store';
import loadField from './loadField';
import { FieldInfo } from '../../../stores/effects/database/field/field_controller';
import { RowInfo } from '../../../stores/effects/database/row/row_cache';
import { ViewLayoutTypePB } from '@/services/backend';
import { DatabaseGroupController } from '$app/stores/effects/database/group/group_controller';

export const useDatabase = (viewId: string, type?: ViewLayoutTypePB) => {
  const dispatch = useAppDispatch();
  const [controller, setController] = useState<DatabaseController>();
  const [rows, setRows] = useState<readonly RowInfo[]>([]);
  const [groups, setGroups] = useState<readonly DatabaseGroupController[]>([]);

  useEffect(() => {
    if (!viewId.length) return;
    const c = new DatabaseController(viewId);
    setController(c);

    // dispose is causing an error
    // return () => void c.dispose();
  }, [viewId]);

  const loadFields = async (fieldInfos: readonly FieldInfo[]) => {
    const fields: DatabaseFieldMap = {};
    const columns: IDatabaseColumn[] = [];

    for (const fieldInfo of fieldInfos) {
      const fieldPB = fieldInfo.field;
      columns.push({
        fieldId: fieldPB.id,
        sort: 'none',
        visible: fieldPB.visibility,
      });

      const field = await loadField(viewId, fieldInfo, dispatch);
      fields[field.fieldId] = field;
    }

    dispatch(databaseActions.updateFields({ fields }));
    dispatch(databaseActions.updateColumns({ columns }));
  };

  useEffect(() => {
    if (!controller) return;

    void (async () => {
      controller.subscribe({
        onRowsChanged: (rowInfos) => {
          setRows(rowInfos);
        },
        onFieldsChanged: (fieldInfos) => {
          void loadFields(fieldInfos);
        },
      });
      await controller.open();

      if (type === ViewLayoutTypePB.Board) {
        setGroups(controller.groups.value);
      }
    })();
  }, [controller]);

  return { loadFields, controller, rows, groups };
};
