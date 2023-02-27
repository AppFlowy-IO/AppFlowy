import { useState } from 'react';
import { gridActions } from '../../../stores/reducers/grid/slice';
import { useAppDispatch } from '../../../stores/store';

export const useGridTableCellHooks = (props: any) => {
  const dispatch = useAppDispatch();
  const [value, setValue] = useState(props.getValue());

  function onValueChange(event: React.ChangeEvent<HTMLInputElement>) {
    setValue(event.target.value);
  }

  function onValueBlur() {
    console.log({ props });
    dispatch(
      gridActions.updateRowValue({ rowId: props.cell.row.original.rowId, cellId: props.cell.id.split('_')[1], value })
    );
  }

  return {
    onValueBlur,
    onValueChange,
    value,
  };
};
