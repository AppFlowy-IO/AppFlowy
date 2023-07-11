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
import { useAppSelector } from '$app/stores/store';

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
  const fields = useAppSelector((state) => state.database.fields);
  const { setShowMenu, showMenu, addRowAt } = useGridTableRow(controller);

  return (
    <Draggable draggableId={row.row.id} key={row.row.id} index={index}>
      {(provided: DraggableProvided, snapshot: DraggableStateSnapshot) => (
        <div
          ref={provided.innerRef}
          {...provided.draggableProps}
          className={`group flex cursor-pointer items-stretch border-b border-shade-6 `}
        >
          {cells.map((cell, cellIndex) => {
            return (
              <div className={`relative flex flex-shrink-0 `} key={cellIndex} draggable={false}>
                <GridCell
                  width={fields[cell.fieldId]?.width}
                  cellIdentifier={cell.cellIdentifier}
                  cellCache={controller.databaseViewCache.getRowCache().getCellCache()}
                  fieldController={controller.fieldController}
                />

                {cellIndex === 0 && (
                  <>
                    {/* <div className='absolute left-[-30px] inset-y-0 my-auto w-8 flex items-center'>
                      <div className={`flex h-5 w-5 group-hover:hidden`}></div>
                      <button
                        className={`hidden h-5 w-5 cursor-pointer items-center rounded hover:bg-main-secondary group-hover:flex ${
                          snapshot.isDragging ? '!flex' : ''
                        }  `}
                        onClick={() => addRowAt(row.row.id)}
                      >
                        <AddSvg />
                      </button>
                    </div>*/}
                    <div className='absolute inset-y-0 left-[-30px] my-auto flex w-8 items-center justify-center'>
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
                        <GridRowActions
                          controller={controller}
                          rowId={row.row.id}
                          onOutsideClick={() => setShowMenu(false)}
                        />
                      )}
                    </div>
                    <div
                      onClick={() => onOpenRow(row)}
                      className='absolute inset-y-0 right-0 my-auto mr-1 hidden h-9 w-9 flex-shrink-0 cursor-pointer rounded p-2 hover:bg-slate-200 group-hover:block '
                    >
                      <FullView />
                    </div>
                  </>
                )}

                <div className={'flex h-full justify-center'}>
                  <div className={'h-full w-[1px] bg-shade-6'}></div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </Draggable>
  );
};
