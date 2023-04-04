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
import { CellOptionsPopup } from '$app/components/_shared/EditRow/CellOptionsPopup';
import { DatePickerPopup } from '$app/components/_shared/EditRow/DatePickerPopup';
import { DragDropContext, Droppable, OnDragEndResponder } from 'react-beautiful-dnd';

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

  const [editingCell, setEditingCell] = useState<CellIdentifier | null>(null);
  const [showFieldEditor, setShowFieldEditor] = useState(false);
  const [editFieldTop, setEditFieldTop] = useState(0);
  const [editFieldRight, setEditFieldRight] = useState(0);

  const [showChangeFieldTypePopup, setShowChangeFieldTypePopup] = useState(false);
  const [changeFieldTypeTop, setChangeFieldTypeTop] = useState(0);
  const [changeFieldTypeRight, setChangeFieldTypeRight] = useState(0);

  const [showChangeOptionsPopup, setShowChangeOptionsPopup] = useState(false);
  const [changeOptionsTop, setChangeOptionsTop] = useState(0);
  const [changeOptionsLeft, setChangeOptionsLeft] = useState(0);

  const [showDatePicker, setShowDatePicker] = useState(false);
  const [datePickerTop, setDatePickerTop] = useState(0);
  const [datePickerLeft, setDatePickerLeft] = useState(0);

  useEffect(() => {
    setUnveil(true);
  }, []);

  const onCloseClick = () => {
    setUnveil(false);
    setTimeout(() => {
      onClose();
    }, 300);
  };

  const onEditFieldClick = (cellIdentifier: CellIdentifier, top: number, right: number) => {
    setEditingCell(cellIdentifier);
    setEditFieldTop(top);
    setEditFieldRight(right);
    setShowFieldEditor(true);
  };

  const onOutsideEditFieldClick = () => {
    if (!showChangeFieldTypePopup) {
      setShowFieldEditor(false);
    }
  };

  const onChangeFieldTypeClick = (buttonTop: number, buttonRight: number) => {
    setChangeFieldTypeTop(buttonTop);
    setChangeFieldTypeRight(buttonRight);
    setShowChangeFieldTypePopup(true);
  };

  const changeFieldType = async (newType: FieldType) => {
    if (!editingCell) return;

    const currentField = controller.fieldController.getField(editingCell.fieldId);
    if (!currentField) return;

    const typeOptionController = new TypeOptionController(viewId, Some(currentField));
    await typeOptionController.switchToField(newType);

    setEditingCell(new CellIdentifier(viewId, rowInfo.row.id, editingCell.fieldId, newType));

    setShowChangeFieldTypePopup(false);
  };

  const onEditOptionsClick = async (cellIdentifier: CellIdentifier, left: number, top: number) => {
    setEditingCell(cellIdentifier);
    setChangeOptionsLeft(left);
    setChangeOptionsTop(top);
    setShowChangeOptionsPopup(true);
  };

  const onEditDateClick = async (cellIdentifier: CellIdentifier, left: number, top: number) => {
    setEditingCell(cellIdentifier);
    setDatePickerLeft(left);
    setDatePickerTop(top);
    setShowDatePicker(true);
  };

  const onDragEnd: OnDragEndResponder = (result) => {
    if (!result.destination?.index) return;
    void controller.moveField({
      fieldId: result.source.droppableId,
      fromIndex: result.source.index,
      toIndex: result.destination.index,
    });
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

        <DragDropContext onDragEnd={onDragEnd}>
          <Droppable droppableId={'field-list'}>
            {(provided) => (
              <div
                {...provided.droppableProps}
                ref={provided.innerRef}
                className={`flex flex-1 flex-col gap-2 ${
                  showFieldEditor || showChangeOptionsPopup || showDatePicker ? 'overflow-hidden' : 'overflow-auto'
                }`}
              >
                {cells.map((cell, cellIndex) => (
                  <EditCellWrapper
                    index={cellIndex}
                    key={cellIndex}
                    cellIdentifier={cell.cellIdentifier}
                    cellCache={controller.databaseViewCache.getRowCache().getCellCache()}
                    fieldController={controller.fieldController}
                    onEditFieldClick={(top: number, right: number) => onEditFieldClick(cell.cellIdentifier, top, right)}
                    onEditOptionsClick={(left: number, top: number) =>
                      onEditOptionsClick(cell.cellIdentifier, left, top)
                    }
                    onEditDateClick={(left: number, top: number) => onEditDateClick(cell.cellIdentifier, left, top)}
                  ></EditCellWrapper>
                ))}
              </div>
            )}
          </Droppable>
        </DragDropContext>

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
            onClick={(newType) => changeFieldType(newType)}
            onOutsideClick={() => setShowChangeFieldTypePopup(false)}
          ></ChangeFieldTypePopup>
        )}
        {showChangeOptionsPopup && editingCell && (
          <CellOptionsPopup
            top={changeOptionsTop}
            left={changeOptionsLeft}
            cellIdentifier={editingCell}
            cellCache={controller.databaseViewCache.getRowCache().getCellCache()}
            fieldController={controller.fieldController}
            onOutsideClick={() => setShowChangeOptionsPopup(false)}
          ></CellOptionsPopup>
        )}
        {showDatePicker && editingCell && (
          <DatePickerPopup
            top={datePickerTop}
            left={datePickerLeft}
            cellIdentifier={editingCell}
            cellCache={controller.databaseViewCache.getRowCache().getCellCache()}
            fieldController={controller.fieldController}
            onOutsideClick={() => setShowDatePicker(false)}
          ></DatePickerPopup>
        )}
      </div>
    </div>
  );
};
