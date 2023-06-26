import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';
import { RowInfo } from '@/appflowy_app/stores/effects/database/row/row_cache';
import { useRow } from '../../_shared/database-hooks/useRow';
import { FullView } from '../../_shared/svg/FullView';
import { GridCell } from '../GridCell/GridCell';
import AddSvg from '../../_shared/svg/AddSvg';
import { DragSvg } from '../../_shared/svg/DragSvg';
import { useGridTableRow } from './GridTableRow.hooks';
import { Draggable, DraggableProvided, DraggableStateSnapshot } from 'react-beautiful-dnd';
import { GridRowActions } from './GridRowActions';

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
  const { setShowMenu, showMenu, addRowAt } = useGridTableRow(controller);

  return (
    <Draggable draggableId={row.row.id} key={row.row.id} index={index}>
      {(provided: DraggableProvided, snapshot: DraggableStateSnapshot) => (
        <tr
          className={`group cursor-pointer ${snapshot.isDragging ? 'flex items-center bg-white' : ''}`}
          ref={provided.innerRef}
          {...provided.draggableProps}
        >
          <td className='w-8'>
            <button
              className={`hidden h-5 w-5 cursor-pointer items-center rounded hover:bg-main-secondary group-hover:flex ${
                snapshot.isDragging ? '!flex' : ''
              }  `}
              onClick={async () => {
                await addRowAt(index);
              }}
            >
              <AddSvg />
            </button>
          </td>
          <td className='w-8'>
            <div className={`flex h-5 w-5 group-hover:hidden`}></div>
            <button
              className={`hidden h-5 w-5 cursor-pointer items-center rounded hover:bg-main-secondary group-hover:flex ${
                snapshot.isDragging ? '!flex' : ''
              }`}
              onClick={() => setShowMenu(true)}
              {...provided.dragHandleProps}
            >
              <DragSvg />
            </button>

            {showMenu && (
              <GridRowActions controller={controller} rowId={row.row.id} onOutsideClick={() => setShowMenu(false)} />
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
