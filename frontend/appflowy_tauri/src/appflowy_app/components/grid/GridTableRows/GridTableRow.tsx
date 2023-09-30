import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';
import { RowInfo } from '@/appflowy_app/stores/effects/database/row/row_cache';
import { useRow } from '../../_shared/database-hooks/useRow';
import { FullView } from '../../_shared/svg/FullView';
import { GridCell } from '../GridCell/GridCell';
import { DragSvg } from '../../_shared/svg/DragSvg';
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

  return (
    // this is needed to prevent DnD from causing exceptions
    cells.length ? (
      <Draggable draggableId={row.row.id} key={row.row.id} index={index}>
        {(provided: DraggableProvided, snapshot: DraggableStateSnapshot) => (
          <div
            ref={provided.innerRef}
            {...provided.draggableProps}
            className={`group/row flex cursor-pointer items-stretch ${snapshot.isDragging ? 'shadow-md' : ''}`}
          >
            <GridRowActions controller={controller} rowId={row.row.id} isDragging={snapshot.isDragging}>
              <i className={`block h-5 w-5`} {...provided.dragHandleProps}>
                <DragSvg />
              </i>
            </GridRowActions>
            {cells
              // filter out hidden fields
              // ?? true is to prevent DnD from causing exceptions
              .filter((cell) => fields[cell.fieldId]?.visible ?? true)
              .map((cell, cellIndex) => {
                return (
                  <div
                    className={`group/cell relative flex flex-shrink-0 border-b border-line-divider bg-bg-body ${
                      snapshot.isDragging ? 'border-t' : ''
                    }`}
                    key={cellIndex}
                    draggable={false}
                  >
                    <GridCell
                      width={fields[cell.fieldId]?.width}
                      cellIdentifier={cell.cellIdentifier}
                      cellCache={controller.databaseViewCache.getRowCache().getCellCache()}
                      fieldController={controller.fieldController}
                    />

                    {cellIndex === 0 && (
                      <div
                        onClick={() => onOpenRow(row)}
                        className='absolute inset-y-0 right-0 my-auto mr-1 hidden flex-shrink-0 cursor-pointer items-center justify-center rounded p-1 hover:bg-fill-list-hover group-hover/cell:flex'
                      >
                        <i className={' block h-5 w-5'}>
                          <FullView />
                        </i>
                      </div>
                    )}

                    <div className={'flex h-full justify-center'}>
                      <div className={'h-full w-[1px] bg-line-divider'}></div>
                    </div>
                  </div>
                );
              })}
            <div
              className={`-ml-1.5 w-40 border-b border-line-divider bg-bg-body ${snapshot.isDragging ? 'border-t' : ''}`}
            ></div>
          </div>
        )}
      </Draggable>
    ) : (
      <></>
    )
  );
};
