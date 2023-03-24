import { CloseSvg } from '$app/components/_shared/svg/CloseSvg';
import { useRow } from '$app/components/_shared/database-hooks/useRow';
import { DatabaseController } from '$app/stores/effects/database/database_controller';
import { RowInfo } from '$app/stores/effects/database/row/row_cache';
import { EditCellWrapper } from '$app/components/_shared/EditRow/EditCellWrapper';
import AddSvg from '$app/components/_shared/svg/AddSvg';
import { useTranslation } from 'react-i18next';
import { EditFieldPopup } from '$app/components/_shared/EditRow/EditFieldPopup';
import { useEffect, useState } from 'react';
import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { ChangeFieldTypePopup } from '$app/components/_shared/EditRow/ChangeFieldTypePopup';
import { TypeOptionController } from '$app/stores/effects/database/field/type_option/type_option_controller';
import { Some } from 'ts-results';
import { FieldType } from '@/services/backend';

export const EditRow = ({
  onClose,
  viewId,
  controller,
  rowInfo,
}: {
  onClose: () => void;
  viewId: string;
  controller: DatabaseController;
  rowInfo: RowInfo;
}) => {
  const { cells, onNewColumnClick } = useRow(viewId, controller, rowInfo);
  const { t } = useTranslation('');
  const [unveil, setUnveil] = useState(false);
  const [showFieldEditor, setShowFieldEditor] = useState(false);
  const [editFieldTop, setEditFieldTop] = useState(0);
  const [editFieldRight, setEditFieldRight] = useState(0);
  const [showChangeFieldTypePopup, setShowChangeFieldTypePopup] = useState(false);
  const [changeFieldTypeTop, setChangeFieldTypeTop] = useState(0);
  const [changeFieldTypeRight, setChangeFieldTypeRight] = useState(0);
  const [editingCell, setEditingCell] = useState<CellIdentifier | null>(null);

  useEffect(() => {
    setUnveil(true);
  }, []);

  const onEditFieldClick = (cellIdentifier: CellIdentifier, top: number, right: number) => {
    setEditingCell(cellIdentifier);
    setEditFieldTop(top);
    setEditFieldRight(right);
    setShowFieldEditor(true);
  };

  const onChangeFieldTypeClick = (buttonTop: number, buttonRight: number) => {
    setChangeFieldTypeTop(buttonTop);
    setChangeFieldTypeRight(buttonRight);
    setShowChangeFieldTypePopup(true);
  };

  const onOutsideEditFieldClick = () => {
    if (!showChangeFieldTypePopup) {
      setShowFieldEditor(false);
    }
  };

  const onCloseClick = () => {
    setUnveil(false);
    setTimeout(() => {
      onClose();
    }, 300);
  };

  const changeFieldTypeClick = async (newType: FieldType) => {
    if (!editingCell) return;

    const currentField = controller.fieldController.getField(editingCell.fieldId);
    if (!currentField) return;

    const typeOptionController = new TypeOptionController(viewId, Some(currentField));
    await typeOptionController.switchToField(newType);

    setEditingCell(new CellIdentifier(viewId, rowInfo.row.id, editingCell.fieldId, newType));

    setShowChangeFieldTypePopup(false);
  };

  return (
    <div
      className={`fixed inset-0 z-10 flex items-center justify-center bg-black/30 backdrop-blur-sm transition-opacity duration-300 ${
        unveil ? 'opacity-100' : 'opacity-0'
      }`}
    >
      <div className={`relative flex h-[90%] w-[70%] flex-col gap-8 rounded-xl bg-white px-8 pb-4 pt-12`}>
        <div onClick={() => onCloseClick()} className={'absolute top-4 right-4'}>
          <button className={'block h-8 w-8 rounded-lg text-shade-2 hover:bg-main-secondary'}>
            <CloseSvg></CloseSvg>
          </button>
        </div>
        <div className={`flex flex-1 flex-col gap-2 ${showFieldEditor ? 'overflow-hidden' : 'overflow-auto'}`}>
          {cells.map((cell, cellIndex) => (
            <EditCellWrapper
              key={cellIndex}
              cellIdentifier={cell.cellIdentifier}
              cellCache={controller.databaseViewCache.getRowCache().getCellCache()}
              fieldController={controller.fieldController}
              onEditFieldClick={(top: number, right: number) => onEditFieldClick(cell.cellIdentifier, top, right)}
            ></EditCellWrapper>
          ))}
        </div>
        {showFieldEditor && editingCell && (
          <EditFieldPopup
            top={editFieldTop}
            right={editFieldRight}
            cellIdentifier={editingCell}
            viewId={viewId}
            onOutsideClick={onOutsideEditFieldClick}
            fieldInfo={controller.fieldController.getField(editingCell.fieldId)}
            changeFieldTypeClick={onChangeFieldTypeClick}
          ></EditFieldPopup>
        )}
        {showChangeFieldTypePopup && (
          <ChangeFieldTypePopup
            top={changeFieldTypeTop}
            right={changeFieldTypeRight}
            onClick={(newType) => changeFieldTypeClick(newType)}
            onOutsideClick={() => setShowChangeFieldTypePopup(false)}
          ></ChangeFieldTypePopup>
        )}
        <div className={'border-t border-shade-6 pt-2'}>
          <button
            onClick={() => onNewColumnClick()}
            className={'flex w-full items-center gap-2 rounded-lg px-4 py-2 hover:bg-shade-6'}
          >
            <i className={'h-5 w-5'}>
              <AddSvg></AddSvg>
            </i>
            <span>{t('grid.field.newColumn')}</span>
          </button>
        </div>
      </div>
    </div>
  );
};
