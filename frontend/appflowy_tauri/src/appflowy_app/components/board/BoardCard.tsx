import { Details2Svg } from '../_shared/svg/Details2Svg';
import { RowInfo } from '../../stores/effects/database/row/row_cache';
import { useRow } from '../_shared/database-hooks/useRow';
import { DatabaseController } from '../../stores/effects/database/database_controller';
import { BoardCell } from './BoardCell';
import { Draggable } from 'react-beautiful-dnd';

export const BoardCard = ({
  index,
  viewId,
  controller,
  rowInfo,
  groupByFieldId,
  onOpenRow,
}: {
  index: number;
  viewId: string;
  controller: DatabaseController;
  rowInfo: RowInfo;
  groupByFieldId: string;
  onOpenRow: (rowId: RowInfo) => void;
}) => {
  const { cells } = useRow(viewId, controller, rowInfo);

  return (
    <Draggable draggableId={rowInfo.row.id} index={index}>
      {(provided) => (
        <div
          ref={provided.innerRef}
          {...provided.draggableProps}
          {...provided.dragHandleProps}
          onClick={() => onOpenRow(rowInfo)}
          className={`relative cursor-pointer select-none rounded-lg border border-shade-6 bg-white px-3 py-2 transition-transform duration-100 hover:bg-main-selector `}
        >
          <button className={'absolute right-4 top-2.5 h-5 w-5 rounded hover:bg-surface-2'}>
            <Details2Svg></Details2Svg>
          </button>
          <div className={'flex flex-col gap-3'}>
            {cells
              .filter((cell) => cell.fieldId !== groupByFieldId)
              .map((cell, cellIndex) => (
                <BoardCell
                  key={cellIndex}
                  cellIdentifier={cell.cellIdentifier}
                  cellCache={controller.databaseViewCache.getRowCache().getCellCache()}
                  fieldController={controller.fieldController}
                ></BoardCell>
              ))}
          </div>
        </div>
      )}
    </Draggable>
  );
};
