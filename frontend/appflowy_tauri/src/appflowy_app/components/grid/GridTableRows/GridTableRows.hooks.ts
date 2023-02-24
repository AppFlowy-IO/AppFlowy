import { useAppSelector } from '../../../stores/store';

export const useGridTableRowsHooks = () => {
  const grid = useAppSelector((state) => state.grid);

  return {
    rows: grid.rows,
  };
};
