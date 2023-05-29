import { CellIdentifier } from '@/appflowy_app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '@/appflowy_app/stores/effects/database/cell/cell_cache';
import { FieldController } from '@/appflowy_app/stores/effects/database/field/field_controller';
import { EditCheckboxCell } from '../../_shared/EditRow/InlineEditFields/EditCheckboxCell';
import { useCell } from '../../_shared/database-hooks/useCell';

export const GridCheckBox = ({
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
    <div className='flex w-full justify-start'>
      {cellController && <EditCheckboxCell cellController={cellController} data={data as 'Yes' | 'No' | undefined} />}
    </div>
  );
};
