import { DateCellDataPB } from '@/services/backend';
import { useCell } from '../_shared/database-hooks/useCell';
import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';

export const BoardDateCell = ({
  cellIdentifier,
  cellCache,
  fieldController,
}: {
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
}) => {
  const { data } = useCell(cellIdentifier, cellCache, fieldController);
  return <div>{(data as DateCellDataPB | undefined)?.date ?? ''}&nbsp;</div>;
};
