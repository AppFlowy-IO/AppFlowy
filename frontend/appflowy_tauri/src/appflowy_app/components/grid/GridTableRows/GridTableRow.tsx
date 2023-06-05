import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';
import { RowInfo } from '@/appflowy_app/stores/effects/database/row/row_cache';
import { useRow } from '../../_shared/database-hooks/useRow';
import { FullView } from '../../_shared/svg/FullView';
import { GridCell } from '../GridCell/GridCell';
import AddSvg from '../../_shared/svg/AddSvg';
import { DragSvg } from '../../_shared/svg/DragSvg';
import { useGridTableRow } from './GridTableRow.hooks';
import { useRef } from 'react';
import useOutsideClick from '../../_shared/useOutsideClick';
import { Draggable, DraggableProvided, DraggableStateSnapshot, Droppable } from 'react-beautiful-dnd';

export const GridTableRow = ({
  viewId,
  controller,
  row,
  onOpenRow,
  index,
}: {
  viewId: string;
  controller: DatabaseController;
  row: RowInfo;
  onOpenRow: (rowId: RowInfo) => void;
  index: number;
}) => {
  const { cells } = useRow(viewId, controller, row);
  const { setShowMenu, showMenu } = useGridTableRow();
  const ref = useRef<HTMLDivElement>(null);
  useOutsideClick(ref, () => setShowMenu(false));

  return (
    <Draggable draggableId={row.row.id} key={row.row.id} index={index}>
      {(provided: DraggableProvided, snapshot: DraggableStateSnapshot) => (
        <tr
          className={`group ${snapshot.isDragging ? 'flex bg-white' : ''}`}
          ref={provided.innerRef}
          {...provided.draggableProps}
        >
          <td className='w-8'>
            <button className=' hidden h-5 w-5 cursor-pointer items-center rounded hover:bg-main-secondary group-hover:flex'>
              <AddSvg />
            </button>
          </td>
          <td {...provided.dragHandleProps} className='w-8'>
            <button
              className=' hidden h-5 w-5 cursor-pointer items-center rounded hover:bg-main-secondary group-hover:flex'
              onClick={() => setShowMenu(true)}
            >
              <DragSvg />
            </button>

            {showMenu && (
              <div className='absolute  w-32 bg-white ' ref={ref}>
                <div className='flex flex-col gap-3 rounded-lg bg-white shadow-md'>
                  <button className='flex cursor-pointer items-center rounded  text-gray-500 hover:bg-main-secondary hover:text-black'>
                    <span>Insert Record</span>
                  </button>
                  <button className='flex cursor-pointer items-center rounded  text-gray-500 hover:bg-main-secondary hover:text-black'>
                    <span>Copy Link</span>
                  </button>
                  <button className='flex cursor-pointer items-center rounded  text-gray-500 hover:bg-main-secondary hover:text-black'>
                    <span>Duplicate</span>
                  </button>
                  <button className='flex cursor-pointer items-center rounded  text-gray-500 hover:bg-main-secondary hover:text-black'>
                    <span>Delete</span>
                  </button>
                </div>
              </div>
            )}
          </td>

          {cells.map((cell, cellIndex) => {
            return (
              <td
                className={`m-0  border border-l-0 border-shade-6 p-0 ${snapshot.isDragging ? 'flex-1  ' : ''}`}
                key={cellIndex}
                draggable={false}
              >
                <div className='flex w-full items-center justify-end'>
                  <GridCell
                    cellIdentifier={cell.cellIdentifier}
                    cellCache={controller.databaseViewCache.getRowCache().getCellCache()}
                    fieldController={controller.fieldController}
                  />

                  {cellIndex === 0 && (
                    <div
                      onClick={() => onOpenRow(row)}
                      className='mr-1 hidden h-9 w-9  cursor-pointer rounded p-2 hover:bg-slate-200 group-hover:block '
                    >
                      <FullView />
                    </div>
                  )}
                </div>
              </td>
            );
          })}

          <td className='w-40' />
        </tr>
      )}
    </Draggable>
  );
};
