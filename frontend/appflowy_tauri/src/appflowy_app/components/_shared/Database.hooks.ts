import { useAppDispatch, useAppSelector } from '../../stores/store';
import { useEffect, useState } from 'react';
import { databaseActions, IDatabase } from '../../stores/reducers/database/slice';
import { nanoid } from 'nanoid';
import { FieldType } from '../../../services/backend';

export const useDatabase = (databaseId: string) => {
  const dispatch = useAppDispatch();
  const databaseStore = useAppSelector((state) => state.database);
  const [database, setDatabase] = useState<IDatabase>();

  useEffect(() => {
    if (!databaseId?.length) return;
    setDatabase(databaseStore[databaseId]);
  }, [databaseId]);

  const newField = () => {
    if (!database) return;

    dispatch(
      databaseActions.addField({
        databaseId,
        field: {
          fieldId: nanoid(8),
          fieldType: FieldType.RichText,
          fieldOptions: {},
          title: 'new field',
        },
      })
    );
  };

  const renameField = (fieldId: string, newTitle: string) => {
    if (!database) return;

    const field = database.fields[fieldId];
    field.title = newTitle;

    dispatch(
      databaseActions.updateField({
        databaseId,
        field,
      })
    );
  };

  const newRow = () => {
    if (!database) return;

    dispatch(databaseActions.addRow({ databaseId }));
  };

  return {
    database,
    newField,
    renameField,
    newRow,
  };
};
