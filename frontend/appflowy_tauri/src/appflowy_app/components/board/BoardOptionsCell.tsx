import { SelectOptionCellDataPB } from '@/services/backend';
import { useCell } from '../_shared/database-hooks/useCell';
import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { getBgColor } from '$app/components/_shared/getColor';

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
    <div className={'flex flex-wrap items-center gap-2 py-2 text-xs text-black'}>
      {(data as SelectOptionCellDataPB)?.select_options?.map((option, index) => (
        <div className={`${getBgColor(option.color)} rounded px-2 py-0.5`} key={index}>
          {option?.name ?? ''}
        </div>
      ))}
      &nbsp;
    </div>
  );
};
