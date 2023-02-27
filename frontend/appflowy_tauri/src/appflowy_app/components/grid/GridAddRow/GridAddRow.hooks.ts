import { gridActions } from '../../../stores/reducers/grid/slice';
import { useAppDispatch } from '../../../stores/store';

export const useGridAddRow = () => {
  const dispatch = useAppDispatch();

  function addRow() {
    dispatch(gridActions.addRow());
  }

  return {
    addRow,
  };
};
