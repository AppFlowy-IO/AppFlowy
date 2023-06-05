import { RowInfo } from '@/appflowy_app/stores/effects/database/row/row_cache';

export const GridTableCount = ({ allRows }: { allRows: readonly RowInfo[] }) => {
  return (
    <span>
      Count : <span className='font-semibold'>{allRows.length || 0}</span>
    </span>
  );
};
