import { RowInfo } from '@/appflowy_app/stores/effects/database/row/row_cache';

export const GridTableCount = ({ rows }: { rows: readonly RowInfo[] }) => {
  const count = rows.length;

  return (
    <span>
      Count : <span className='font-semibold'>{count}</span>
    </span>
  );
};
