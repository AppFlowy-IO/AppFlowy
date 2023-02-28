import { useAppSelector } from '../../../stores/store';

export const useGridTableCount = () => {
  const { database } = useAppSelector((state) => state);
  const { rows } = database;

  return {
    count: rows.length,
  };
};
