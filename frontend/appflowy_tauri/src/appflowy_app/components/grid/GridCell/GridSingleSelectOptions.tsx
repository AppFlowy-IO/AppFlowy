import { useState } from 'react';
import { CellOptions } from '$app/components/_shared/EditRow/Options/CellOptions';
import { CellIdentifier } from '@/appflowy_app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '@/appflowy_app/stores/effects/database/cell/cell_cache';
import { FieldController } from '@/appflowy_app/stores/effects/database/field/field_controller';
import { useCell } from '$app/components/_shared/database-hooks/useCell';
import { CellOptionsPopup } from '$app/components/_shared/EditRow/Options/CellOptionsPopup';
import { EditCellOptionPopup } from '$app/components/_shared/EditRow/Options/EditCellOptionPopup';
import { SelectOptionCellDataPB, SelectOptionPB } from '@/services/backend';

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

  const [showEditCellOption, setShowEditCellOption] = useState(false);
  const [editCellOptionTop, setEditCellOptionTop] = useState(0);
  const [editCellOptionLeft, setEditCellOptionLeft] = useState(0);

  const [editingSelectOption, setEditingSelectOption] = useState<SelectOptionPB | undefined>();

  const onEditOptionsClick = async (left: number, top: number) => {
    setChangeOptionsLeft(left);
    setChangeOptionsTop(top);
    setShowOptionsPopup(true);
  };

  const onOpenOptionDetailClick = (_left: number, _top: number, _select_option: SelectOptionPB) => {
    setEditingSelectOption(_select_option);
    setShowEditCellOption(true);
    setEditCellOptionLeft(_left);
    setEditCellOptionTop(_top);
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
          openOptionDetail={onOpenOptionDetailClick}
        />
      )}
      {showEditCellOption && editingSelectOption && (
        <EditCellOptionPopup
          top={editCellOptionTop}
          left={editCellOptionLeft}
          cellIdentifier={cellIdentifier}
          editingSelectOption={editingSelectOption}
          onOutsideClick={() => {
            setShowEditCellOption(false);
          }}
        ></EditCellOptionPopup>
      )}
    </>
  );
}
