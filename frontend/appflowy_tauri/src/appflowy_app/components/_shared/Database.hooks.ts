import { useAppSelector } from '$app/stores/store';

export const useDatabase = () => {
  const database = useAppSelector((state) => state.database);

  const newField = () => {
    /* dispatch(
      databaseActions.addField({
        field: {
          fieldId: nanoid(8),
          fieldType: FieldType.RichText,
          fieldOptions: {},
          title: 'new field',
        },
      })
    );*/
    console.log('depreciated');
  };

  const renameField = (_fieldId: string, _newTitle: string) => {
    /*   const field = database.fields[fieldId];
    field.title = newTitle;

    dispatch(
      databaseActions.updateField({
        field,
      })
    );*/
    console.log('depreciated');
  };

  const newRow = () => {
    // dispatch(databaseActions.addRow());
    console.log('depreciated');
  };

  return {
    database,
    newField,
    renameField,
    newRow,
  };
};
