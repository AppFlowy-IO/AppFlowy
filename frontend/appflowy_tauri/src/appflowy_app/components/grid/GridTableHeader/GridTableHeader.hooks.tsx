import { nanoid } from 'nanoid';
import { FieldType } from '../../../../services/backend/classes/flowy-database/field_entities';
import { gridActions } from '../../../redux/grid/slice';
import { useAppDispatch, useAppSelector } from '../../../store';

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
