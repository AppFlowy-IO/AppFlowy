import { nanoid } from 'nanoid';
import { FieldType } from '@/services/backend/models/flowy-database/field_entities';
import { gridActions } from '../../../stores/reducers/grid/slice';
import { useAppDispatch, useAppSelector } from '../../../stores/store';

export const useGridTableHeaderHooks = function () {
  const dispatch = useAppDispatch();
  const grid = useAppSelector((state) => state.grid);

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
    fields: grid.fields,
    onAddField,
  };
};
