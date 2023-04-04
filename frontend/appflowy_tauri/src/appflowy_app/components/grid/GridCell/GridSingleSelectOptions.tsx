import { useState, useEffect, useRef } from 'react';
import { CellOptions } from '../../_shared/EditRow/CellOptions';
import { CellIdentifier } from '@/appflowy_app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '@/appflowy_app/stores/effects/database/cell/cell_cache';
import { FieldController } from '@/appflowy_app/stores/effects/database/field/field_controller';
import { useCell } from '../../_shared/database-hooks/useCell';
import { SelectOptionCellDataPB } from '@/services/backend/models/flowy-database/select_type_option';

export default function GridSingleSelectOptions({
  cellIdentifier,
  cellCache,
  fieldController,
}: {
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
}) {
  const ref = useRef<HTMLDivElement>(null);

  const { data, cellController } = useCell(cellIdentifier, cellCache, fieldController);

  const [value, setValue] = useState((data as SelectOptionCellDataPB) || '');
  const [showOptionsPopup, setShowOptionsPopup] = useState(false);

  useEffect(() => {
    if (data) setValue(data as SelectOptionCellDataPB);
  }, [data]);
  return (
    <>
      <div className='flex w-full justify-start' ref={ref}>
        <CellOptions data={data as SelectOptionCellDataPB} onEditClick={() => setShowOptionsPopup(!showOptionsPopup)} />
      </div>
    </>
  );
}
