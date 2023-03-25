import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { useEffect, useState } from 'react';
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
  const { data, cellController } = useCell(cellIdentifier, cellCache, fieldController);

  const [value, setValue] = useState((data as string) || '');

  useEffect(() => {
    if (data) setValue(data as string);
  }, [data]);

  return (
    <div>
      <input
        value={value}
        onChange={(e) => {
          setValue(e.target.value);
        }}
        onBlur={async () => {
          await cellController?.saveCellData(value);
        }}
        className='min-h-[32px] w-full p-2 focus:border focus:border-main-accent focus:outline-none '
      />
    </div>
  );
};
