import { CellIdentifier } from '@/appflowy_app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '@/appflowy_app/stores/effects/database/cell/cell_cache';
import { FieldController } from '@/appflowy_app/stores/effects/database/field/field_controller';
import { BoardCell } from '../../board/BoardCell';

export const GridTableCell = ({
  cellIdentifier,
  cellCache,
  fieldController,
  onClick,
}: {
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
  onClick: () => void;
}) => {
  return (
    <div onClick={() => onClick()} className='w-full rounded-lg border border-transparent group-active:bg-main-accent'>
      <BoardCell cellIdentifier={cellIdentifier} cellCache={cellCache} fieldController={fieldController} />
    </div>
  );
};
