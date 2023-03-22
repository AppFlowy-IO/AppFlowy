import { Details2Svg } from '../_shared/svg/Details2Svg';
import { RowInfo } from '../../stores/effects/database/row/row_cache';
import { useRow } from '../_shared/database-hooks/useRow';
import { DatabaseController } from '../../stores/effects/database/database_controller';
import { BoardCell } from './BoardCell';

export const BoardCard = ({
  viewId,
  controller,
  rowInfo,
}: {
  viewId: string;
  controller: DatabaseController;
  rowInfo: RowInfo;
}) => {
  const { cells } = useRow(viewId, controller, rowInfo);

  return (
    <div
      onClick={() => console.log('on click')}
      className={`relative cursor-pointer select-none rounded-lg border border-shade-6 bg-white px-3 py-2 transition-transform duration-100 hover:bg-main-selector `}
    >
      <button className={'absolute right-4 top-2.5 h-5 w-5 rounded hover:bg-surface-2'}>
        <Details2Svg></Details2Svg>
      </button>
      <div className={'flex flex-col gap-3'}>
        {cells.map((cell, index) => (
          <BoardCell
            key={index}
            cellIdentifier={cell.cellIdentifier}
            cellCache={controller.databaseViewCache.getRowCache().getCellCache()}
            fieldController={controller.fieldController}
          ></BoardCell>
        ))}
      </div>
    </div>
  );
};
