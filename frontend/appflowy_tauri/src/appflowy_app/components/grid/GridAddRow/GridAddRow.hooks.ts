import { databaseActions } from '../../../stores/reducers/database/slice';
import { useAppDispatch } from '../../../stores/store';

export const useGridAddRow = () => {
  const dispatch = useAppDispatch();

  function addRow() {
    dispatch(databaseActions.addRow());
  }

  return {
    addRow,
  };
};
