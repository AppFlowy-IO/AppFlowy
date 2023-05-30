import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { useCell } from '$app/components/_shared/database-hooks/useCell';
import { URLCellDataPB } from '@/services/backend';

export const BoardUrlCell = ({
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
      <a className={'text-main-accent hover:underline'} href={(data as URLCellDataPB)?.url ?? ''} target={'_blank'}>
        {(data as URLCellDataPB)?.content ?? ''}&nbsp;
      </a>
    </>
  );
};
