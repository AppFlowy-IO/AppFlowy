import { FieldType } from '../../../../services/backend';
import { databaseActions } from '../../../stores/reducers/database/slice';

import { useAppDispatch, useAppSelector } from '../../../stores/store';

export const GridTableHeaderHooks = () => {
  const dispatch = useAppDispatch();

  const database = useAppSelector((state) => state.database);

  const onAddField = () => {
    dispatch(
      databaseActions.addField({
        field: {
          fieldId: `field${database.columns.length + 1}`,
          title: 'Name',
          fieldOptions: {},
          fieldType: FieldType.RichText,
        },
      })
    );
  };

  return {
    onAddField,
  };
};
