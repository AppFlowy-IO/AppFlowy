import { useAppSelector } from '$app/stores/store';

export const useGridTableCount = () => {
  const { grid } = useAppSelector((state) => state);
  const { rows } = grid;

  return {
    count: rows.length,
  };
};
