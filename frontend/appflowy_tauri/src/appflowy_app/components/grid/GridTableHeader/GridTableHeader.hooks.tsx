import { nanoid } from 'nanoid';
import { FieldType } from '../../../../services/backend';
import { gridActions } from '../../../stores/reducers/grid/slice';
import { useAppDispatch } from '../../../stores/store';

export const GridTableHeaderHooks = () => {
  const dispatch = useAppDispatch();

  const onAddField = () => {
    dispatch(
      gridActions.addField({
        field: {
          fieldId: nanoid(8),
          name: 'Name',
          fieldOptions: {},
          fieldType: FieldType.RichText,
          size: 300,
        },
      })
    );
  };

  return {
    onAddField,
  };
};
