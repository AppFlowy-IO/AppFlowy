import { useEffect, useState } from 'react';
import { DatabaseController } from '../../../stores/effects/database/database_controller';
import {
  databaseActions,
  DatabaseFieldMap,
  IDatabaseColumn,
  IDatabaseRow,
} from '../../../stores/reducers/database/slice';
import { useAppDispatch, useAppSelector } from '../../../stores/store';
import loadField from './loadField';
import { FieldInfo } from '../../../stores/effects/database/field/field_controller';

export const useDatabase = (viewId: string) => {
  const dispatch = useAppDispatch();
  const databaseStore = useAppSelector((state) => state.database);
  const boardStore = useAppSelector((state) => state.board);
  const [controller, setController] = useState<DatabaseController>();

  useEffect(() => {
    if (!viewId.length) return;
    const c = new DatabaseController(viewId);
    setController(c);

    // on unmount dispose the controller
    return () => void c.dispose();
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
    console.log(fields, columns);
  };

  return { loadFields, controller };
};
