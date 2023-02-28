import { useState } from 'react';
import { databaseActions } from '../../../stores/reducers/database/slice';
import { useAppDispatch } from '../../../stores/store';

export const useGridTableCellHooks = (props: any) => {
  const dispatch = useAppDispatch();
  const [value, setValue] = useState(props.getValue().data);

  function onValueChange(event: React.ChangeEvent<HTMLInputElement>) {
    setValue(event.target.value);
  }

  function onValueBlur() {
    const updatedCell = { ...props.getValue(), data: value };
    dispatch(
      databaseActions.updateCellValue({
        cell: updatedCell,
      })
    );
  }

  return {
    onValueBlur,
    onValueChange,
    value,
  };
};
