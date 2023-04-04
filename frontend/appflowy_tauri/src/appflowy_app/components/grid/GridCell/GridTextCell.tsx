import { CellIdentifier } from '@/appflowy_app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '@/appflowy_app/stores/effects/database/cell/cell_cache';
import { FieldController } from '@/appflowy_app/stores/effects/database/field/field_controller';
import { useState, useEffect } from 'react';
import { useCell } from '../../_shared/database-hooks/useCell';

export default function GridTextCell({
  cellIdentifier,
  cellCache,
  fieldController,
}: {
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
}) {
  const { data, cellController } = useCell(cellIdentifier, cellCache, fieldController);

  const [value, setValue] = useState((data as string) || '');

  useEffect(() => {
    if (data) setValue(data as string);
  }, [data]);
  return (
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
  );
}
