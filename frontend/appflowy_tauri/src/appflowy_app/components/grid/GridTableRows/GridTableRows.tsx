import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';
import { RowInfo } from '@/appflowy_app/stores/effects/database/row/row_cache';
import { GridTableRow } from './GridTableRow';
import { DragDropContext, Droppable, DroppableProvided, OnDragEndResponder } from 'react-beautiful-dnd';

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
  const onRowsDragEnd: OnDragEndResponder = async (result) => {
    if (!result.destination) return;
    if (result.destination.index === result.source.index) return;
    await controller.moveRow(result.draggableId, allRows[result.destination.index].row.id);
  };

  return (
    <DragDropContext onDragEnd={onRowsDragEnd}>
      <Droppable droppableId='table'>
        {(droppableProvided: DroppableProvided) => (
          <div
            className={'absolute h-full overflow-y-auto overflow-x-hidden'}
            ref={droppableProvided.innerRef}
            {...droppableProvided.droppableProps}
          >
            {allRows.map((row, i) => {
              return (
                <GridTableRow
                  onOpenRow={onOpenRow}
                  row={row}
                  key={i}
                  index={i}
                  viewId={viewId}
                  controller={controller}
                />
              );
            })}
            {droppableProvided.placeholder}
          </div>
        )}
      </Droppable>
    </DragDropContext>
  );
};
