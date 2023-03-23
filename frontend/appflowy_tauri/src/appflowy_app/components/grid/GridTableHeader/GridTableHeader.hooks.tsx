import { nanoid } from 'nanoid';
import { FieldType } from '@/services/backend/models/flowy-database/field_entities';
import { gridActions } from '../../../stores/reducers/grid/slice';
import { useAppDispatch, useAppSelector } from '../../../stores/store';

export const useGridTableHeaderHooks = function () {
  const dispatch = useAppDispatch();
  const database = useAppSelector((state) => state.database);

  const onAddField = () => {
    dispatch(
      gridActions.addField({
        field: {
          fieldId: nanoid(8),
          name: 'Name',
          fieldOptions: {},
          fieldType: FieldType.RichText,
        },
      })
    );
  };

  return {
    fields: Object.values(database.fields).map((field) => {
      return {
        fieldId: field.fieldId,
        name: field.title,
        fieldType: field.fieldType,
      };
    }),
    onAddField,
  };
};
