import { CellIdentifier } from '@/appflowy_app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '@/appflowy_app/stores/effects/database/cell/cell_cache';
import { FieldController } from '@/appflowy_app/stores/effects/database/field/field_controller';
import { BoardCell } from '../../board/BoardCell';
import { useCell } from '../../_shared/database-hooks/useCell';

export const GridTableCell = ({
  cellIdentifier,
  cellCache,
  fieldController,
}: {
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
}) => {
  const { data } = useCell(cellIdentifier, cellCache, fieldController);

  console.log({ data });

  return (
    <div className='min-h-[32px] w-full rounded-lg border border-transparent p-2 focus:border-main-accent'>
      <BoardCell cellIdentifier={cellIdentifier} cellCache={cellCache} fieldController={fieldController} />
    </div>
  );
};
