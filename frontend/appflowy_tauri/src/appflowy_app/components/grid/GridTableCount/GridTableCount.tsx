import { useGridTableCount } from './GridTableCount.hooks';

export const GridTableCount = () => {
  const { count } = useGridTableCount();
  return (
    <span>
      Count : <span className='font-semibold'>{count}</span>
    </span>
  );
};
