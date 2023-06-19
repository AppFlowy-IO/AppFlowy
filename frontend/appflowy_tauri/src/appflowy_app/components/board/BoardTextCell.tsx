import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { useCell } from '../_shared/database-hooks/useCell';

export const BoardTextCell = ({
  cellIdentifier,
  cellCache,
  fieldController,
}: {
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
}) => {
  const { data } = useCell(cellIdentifier, cellCache, fieldController);

  return (
    <div>
      {((data as string | undefined) ?? '').split('\n').map((line, index) => (
        <div key={index}>{line}</div>
      ))}
      &nbsp;
    </div>
  );
};
