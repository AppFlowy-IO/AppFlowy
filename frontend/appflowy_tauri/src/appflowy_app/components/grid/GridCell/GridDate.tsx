import { CellIdentifier } from '@/appflowy_app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '@/appflowy_app/stores/effects/database/cell/cell_cache';
import { FieldController } from '@/appflowy_app/stores/effects/database/field/field_controller';
import { useCell } from '../../_shared/database-hooks/useCell';
import { DateCellDataPB } from '@/services/backend';
import { EditCellDate } from '../../_shared/EditRow/Date/EditCellDate';
import { useState } from 'react';
import { DatePickerPopup } from '../../_shared/EditRow/Date/DatePickerPopup';

export const GridDate = ({
  cellIdentifier,
  cellCache,
  fieldController,
}: {
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
}) => {
  const { data, cellController } = useCell(cellIdentifier, cellCache, fieldController);

  const [showDatePopup, setShowDatePopup] = useState(false);
  const [datePickerTop, setdatePickerTop] = useState(0);
  const [datePickerLeft, setdatePickerLeft] = useState(0);

  const onEditDateClick = async (left: number, top: number) => {
    setdatePickerLeft(left);
    setdatePickerTop(top);
    setShowDatePopup(true);
  };

  return (
    <div className='flex w-full cursor-pointer justify-start'>
      {cellController && <EditCellDate data={data as DateCellDataPB} onEditClick={onEditDateClick}></EditCellDate>}

      {showDatePopup && (
        <DatePickerPopup
          top={datePickerTop}
          left={datePickerLeft}
          cellIdentifier={cellIdentifier}
          cellCache={cellCache}
          fieldController={fieldController}
          onOutsideClick={() => setShowDatePopup(false)}
        ></DatePickerPopup>
      )}
    </div>
  );
};
