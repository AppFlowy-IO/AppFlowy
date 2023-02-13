import { gridActions } from '../../../redux/grid/slice';
import { useAppDispatch } from '../../../store';

export const useGridAddRow = () => {
  const dispatch = useAppDispatch();

  function addRow() {
    dispatch(gridActions.addRow());
  }

  return {
    addRow,
  };
};
