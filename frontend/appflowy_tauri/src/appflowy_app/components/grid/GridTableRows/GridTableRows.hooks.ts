import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';
import { RowInfo } from '@/appflowy_app/stores/effects/database/row/row_cache';
import { OnDragEndResponder } from 'react-beautiful-dnd';

export const useGridTableRows = (controller: DatabaseController, allRows: readonly RowInfo[]) => {
  const onRowsDragEnd: OnDragEndResponder = async (result) => {
    console.log({ result });
    // TODO: move row to index
    // await controller.moveRow(result.draggableId, result.destination?.index ?? 0);
  };

  return {
    onRowsDragEnd,
  };
};
