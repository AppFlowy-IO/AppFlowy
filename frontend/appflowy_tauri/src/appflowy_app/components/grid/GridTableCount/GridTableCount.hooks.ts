import { useAppSelector } from '../../../store';

export const useGridTableCount = () => {
  const { grid } = useAppSelector((state) => state);
  const { rows } = grid;

  return {
    count: rows.length,
  };
};
