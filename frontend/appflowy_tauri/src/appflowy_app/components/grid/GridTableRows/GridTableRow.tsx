import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';
import { RowInfo } from '@/appflowy_app/stores/effects/database/row/row_cache';
import { useRow } from '../../_shared/database-hooks/useRow';
import { FullView } from '../../_shared/svg/FullView';
import { GridCell } from '../GridCell/GridCell';

export const GridTableRow = ({
  viewId,
  controller,
  row,
  onOpenRow,
}: {
  viewId: string;
  controller: DatabaseController;
  row: RowInfo;
  onOpenRow: (rowId: RowInfo) => void;
}) => {
  const { cells } = useRow(viewId, controller, row);

  return (
    <tr className='group'>
      {cells.map((cell, cellIndex) => {
        return (
          <td className='m-0  border border-l-0 border-line-divider p-0 ' key={cellIndex}>
            <div className='flex w-full items-center justify-end'>
              <GridCell
                cellIdentifier={cell.cellIdentifier}
                cellCache={controller.databaseViewCache.getRowCache().getCellCache()}
                fieldController={controller.fieldController}
              />

              {cellIndex === 0 && (
                <div
                  onClick={() => onOpenRow(row)}
                  className='mr-1 hidden h-8 w-8 cursor-pointer rounded p-1.5 text-text-caption hover:bg-fill-list-hover group-hover:block '
                >
                  <FullView />
                </div>
              )}
            </div>
          </td>
        );
      })}
    </tr>
  );
};
