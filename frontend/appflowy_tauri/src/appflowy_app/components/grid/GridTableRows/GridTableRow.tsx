import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';
import { RowInfo } from '@/appflowy_app/stores/effects/database/row/row_cache';
import { useRow } from '../../_shared/database-hooks/useRow';
import { FullView } from '../../_shared/svg/FullView';
import { GridCell } from '../GridCell/GridCell';
import { DragSvg } from '../../_shared/svg/DragSvg';
import { Draggable, DraggableProvided, DraggableStateSnapshot } from 'react-beautiful-dnd';
import { GridRowActions } from './GridRowActions';
import { useAppSelector } from '$app/stores/store';
import { useState } from 'react';

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
  const [showMenu, setShowMenu] = useState(false);

  return (
    // this is needed to prevent DnD from causing exceptions
    cells.length ? (
      <Draggable draggableId={row.row.id} key={row.row.id} index={index}>
        {(provided: DraggableProvided, snapshot: DraggableStateSnapshot) => (
          <div
            ref={provided.innerRef}
            {...provided.draggableProps}
            className={`group flex cursor-pointer items-stretch border-b border-line-divider `}
          >
            {cells
              .filter((cell) => fields[cell.fieldId].visible)
              .map((cell, cellIndex) => {
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
                        <div className='absolute inset-y-0 left-[-30px] my-auto flex w-8 items-center justify-center'>
                          <button
                            className={`hidden h-5 w-5 cursor-pointer items-center rounded hover:bg-fill-list-hover group-hover:flex ${
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
                          className=' absolute inset-y-0 right-0 my-auto mr-1 hidden flex-shrink-0 cursor-pointer items-center justify-center rounded p-1 hover:bg-fill-list-hover group-hover:flex '
                        >
                          <i className={' block h-5 w-5'}>
                            <FullView />
                          </i>
                        </div>
                      </>
                    )}

                    <div className={'flex h-full justify-center'}>
                      <div className={'h-full w-[1px] bg-line-divider'}></div>
                    </div>
                  </div>
                );
              })}
          </div>
        )}
      </Draggable>
    ) : (
      <></>
    )
  );
};
