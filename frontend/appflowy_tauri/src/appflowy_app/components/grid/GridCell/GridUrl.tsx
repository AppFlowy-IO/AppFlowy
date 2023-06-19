import { CellIdentifier } from '@/appflowy_app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '@/appflowy_app/stores/effects/database/cell/cell_cache';
import { FieldController } from '@/appflowy_app/stores/effects/database/field/field_controller';
import { useCell } from '../../_shared/database-hooks/useCell';
import { EditCellUrl } from '../../_shared/EditRow/InlineEditFields/EditCellUrl';
import { URLCellDataPB } from '@/services/backend';

export const GridUrl = ({
  cellIdentifier,
  cellCache,
  fieldController,
}: {
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
}) => {
  const { data, cellController } = useCell(cellIdentifier, cellCache, fieldController);

  return (
    <>{cellController && <EditCellUrl data={data as URLCellDataPB} cellController={cellController}></EditCellUrl>}</>
  );
};
