import { useAppDispatch, useAppSelector } from '../../stores/store';
import { useEffect, useState } from 'react';
import { databaseActions, IDatabase } from '../../stores/reducers/database/slice';
import { nanoid } from 'nanoid';
import { FieldType } from '../../../services/backend';

export const useDatabase = () => {
  const dispatch = useAppDispatch();
  const database = useAppSelector((state) => state.database);

  const newField = () => {
    dispatch(
      databaseActions.addField({
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
    const field = database.fields[fieldId];
    field.title = newTitle;

    dispatch(
      databaseActions.updateField({
        field,
      })
    );
  };

  const newRow = () => {
    dispatch(databaseActions.addRow());
  };

  return {
    database,
    newField,
    renameField,
    newRow,
  };
};
