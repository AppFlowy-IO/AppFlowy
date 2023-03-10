import { SelectOptionCellDataPB } from '../../../services/backend';
import { useCell } from '../_shared/database-hooks/useCell';
import { CellIdentifier } from '../../stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '../../stores/effects/database/cell/cell_cache';
import { FieldController } from '../../stores/effects/database/field/field_controller';

export const BoardOptionsCell = ({
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
    <>
      {(data as SelectOptionCellDataPB | undefined)?.select_options?.map((option, index) => (
        <div key={index}>{option?.name || ''}</div>
      )) || ''}
    </>
  );
};
