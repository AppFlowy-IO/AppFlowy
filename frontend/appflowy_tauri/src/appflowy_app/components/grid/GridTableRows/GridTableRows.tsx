import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';
import { RowInfo } from '@/appflowy_app/stores/effects/database/row/row_cache';
import { GridTableRow } from './GridTableRow';
export const GridTableRows = ({
  viewId,
  controller,
  allRows,
  onOpenRow,
}: {
  viewId: string;
  controller: DatabaseController;
  allRows: readonly RowInfo[];
  onOpenRow: (rowId: RowInfo) => void;
}) => {
  return (
    <tbody>
      {allRows.map((row, i) => {
        return <GridTableRow onOpenRow={onOpenRow} row={row} key={i} viewId={viewId} controller={controller} />;
      })}
    </tbody>
  );
};
