import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';
import { RowInfo } from '@/appflowy_app/stores/effects/database/row/row_cache';
import { useRow } from '../../_shared/database-hooks/useRow';
import { GridTableCell } from './GridTableCell';

export const GridTableRow = ({
  viewId,
  controller,
  row,
}: {
  viewId: string;
  controller: DatabaseController;
  row: RowInfo;
}) => {
  const { cells } = useRow(viewId, controller, row);

  console.log({ cells });
  return (
    <tr>
      {cells.map((cell, cellIndex) => {
        return (
          <td className='m-0 border border-l-0 border-shade-6 p-0 ' key={cellIndex}>
            <GridTableCell
              key={cellIndex}
              cellIdentifier={cell.cellIdentifier}
              cellCache={controller.databaseViewCache.getRowCache().getCellCache()}
              fieldController={controller.fieldController}
            />
          </td>
        );
      })}
    </tr>
  );
};
