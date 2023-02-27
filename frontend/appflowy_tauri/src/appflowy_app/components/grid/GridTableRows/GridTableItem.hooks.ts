import { useState } from 'react';
import { gridActions } from '../../../stores/reducers/grid/slice';
import { useAppDispatch, useAppSelector } from '../../../stores/store';

export const useGridTableItemHooks = (
  rowItem: { value: string | number; fieldId: string; cellId: string },
  rowId: string
) => {
  const dispatch = useAppDispatch();
  const [value, setValue] = useState(rowItem.value);

  function onValueChange(event: React.ChangeEvent<HTMLInputElement>) {
    setValue(event.target.value);
  }

  function onValueBlur() {
    dispatch(gridActions.updateRowValue({ rowId: rowId, cellId: rowItem.cellId, value }));
  }

  const grid = useAppSelector((state) => state.grid);

  return {
    rows: grid.rows,
    onValueChange,
    value,
    onValueBlur,
  };
};
