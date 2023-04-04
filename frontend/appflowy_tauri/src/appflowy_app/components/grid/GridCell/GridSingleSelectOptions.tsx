import { useState } from 'react';
import { CellOptions } from '../../_shared/EditRow/CellOptions';
import { CellIdentifier } from '@/appflowy_app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '@/appflowy_app/stores/effects/database/cell/cell_cache';
import { FieldController } from '@/appflowy_app/stores/effects/database/field/field_controller';
import { useCell } from '../../_shared/database-hooks/useCell';
import { SelectOptionCellDataPB } from '@/services/backend/models/flowy-database/select_type_option';
import { CellOptionsPopup } from '../../_shared/EditRow/CellOptionsPopup';

export default function GridSingleSelectOptions({
  cellIdentifier,
  cellCache,
  fieldController,
}: {
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
}) {
  const { data } = useCell(cellIdentifier, cellCache, fieldController);

  const [showOptionsPopup, setShowOptionsPopup] = useState(false);
  const [changeOptionsTop, setChangeOptionsTop] = useState(0);
  const [changeOptionsLeft, setChangeOptionsLeft] = useState(0);

  const onEditOptionsClick = async (left: number, top: number) => {
    setChangeOptionsLeft(left);
    setChangeOptionsTop(top);
    setShowOptionsPopup(true);
  };

  return (
    <>
      <div className='flex w-full cursor-pointer justify-start'>
        <CellOptions data={data as SelectOptionCellDataPB} onEditClick={onEditOptionsClick} />
      </div>

      {showOptionsPopup && (
        <CellOptionsPopup
          top={changeOptionsTop}
          left={changeOptionsLeft}
          cellIdentifier={cellIdentifier}
          cellCache={cellCache}
          fieldController={fieldController}
          onOutsideClick={() => setShowOptionsPopup(false)}
        />
      )}
    </>
  );
}
