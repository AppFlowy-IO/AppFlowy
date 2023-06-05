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
import { FieldType, SelectOptionPB } from '@/services/backend';
import { CellOptionsPopup } from '$app/components/_shared/EditRow/Options/CellOptionsPopup';
import { DatePickerPopup } from '$app/components/_shared/EditRow/Date/DatePickerPopup';
import { DragDropContext, Droppable, OnDragEndResponder } from 'react-beautiful-dnd';
import { EditCellOptionPopup } from '$app/components/_shared/EditRow/Options/EditCellOptionPopup';
import { NumberFormatPopup } from '$app/components/_shared/EditRow/Date/NumberFormatPopup';
import { CheckListPopup } from '$app/components/_shared/EditRow/CheckList/CheckListPopup';
import { EditCheckListPopup } from '$app/components/_shared/EditRow/CheckList/EditCheckListPopup';
import { PropertiesPanel } from '$app/components/_shared/EditRow/PropertiesPanel';
import { ImageSvg } from '$app/components/_shared/svg/ImageSvg';
import { PromptWindow } from '$app/components/_shared/PromptWindow';
import { useAppSelector } from '$app/stores/store';

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
  const databaseStore = useAppSelector((state) => state.database);
  const { cells, onNewColumnClick } = useRow(viewId, controller, rowInfo);
  const { t } = useTranslation();
  const [unveil, setUnveil] = useState(false);

  const [editingCell, setEditingCell] = useState<CellIdentifier | null>(null);
  const [showFieldEditor, setShowFieldEditor] = useState(false);
  const [editFieldTop, setEditFieldTop] = useState(0);
  const [editFieldLeft, setEditFieldLeft] = useState(0);

  const [showChangeFieldTypePopup, setShowChangeFieldTypePopup] = useState(false);
  const [changeFieldTypeTop, setChangeFieldTypeTop] = useState(0);
  const [changeFieldTypeLeft, setChangeFieldTypeLeft] = useState(0);

  const [showChangeOptionsPopup, setShowChangeOptionsPopup] = useState(false);
  const [changeOptionsTop, setChangeOptionsTop] = useState(0);
  const [changeOptionsLeft, setChangeOptionsLeft] = useState(0);

  const [showDatePicker, setShowDatePicker] = useState(false);
  const [datePickerTop, setDatePickerTop] = useState(0);
  const [datePickerLeft, setDatePickerLeft] = useState(0);

  const [showEditCellOption, setShowEditCellOption] = useState(false);
  const [editCellOptionTop, setEditCellOptionTop] = useState(0);
  const [editCellOptionLeft, setEditCellOptionLeft] = useState(0);

  const [editingSelectOption, setEditingSelectOption] = useState<SelectOptionPB | undefined>();

  const [showEditCheckList, setShowEditCheckList] = useState(false);
  const [editCheckListTop, setEditCheckListTop] = useState(0);
  const [editCheckListLeft, setEditCheckListLeft] = useState(0);

  const [showNumberFormatPopup, setShowNumberFormatPopup] = useState(false);
  const [numberFormatTop, setNumberFormatTop] = useState(0);
  const [numberFormatLeft, setNumberFormatLeft] = useState(0);

  const [showCheckListPopup, setShowCheckListPopup] = useState(false);
  const [checkListPopupTop, setCheckListPopupTop] = useState(0);
  const [checkListPopupLeft, setCheckListPopupLeft] = useState(0);

  const [deletingPropertyId, setDeletingPropertyId] = useState<string | null>(null);
  const [showDeletePropertyPrompt, setShowDeletePropertyPrompt] = useState(false);

  useEffect(() => {
    setUnveil(true);
  }, []);

  const onCloseClick = () => {
    setUnveil(false);
    setTimeout(() => {
      onClose();
    }, 300);
  };

  const onEditFieldClick = (cellIdentifier: CellIdentifier, left: number, top: number) => {
    setEditingCell(cellIdentifier);
    setEditFieldTop(top);
    setEditFieldLeft(left + 10);
    setShowFieldEditor(true);
  };

  const onOutsideEditFieldClick = () => {
    if (!showChangeFieldTypePopup) {
      setShowFieldEditor(false);
    }
  };

  const onChangeFieldTypeClick = (buttonTop: number, buttonRight: number) => {
    setChangeFieldTypeTop(buttonTop);
    setChangeFieldTypeLeft(buttonRight + 30);
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
    setChangeOptionsTop(top + 40);
    setShowChangeOptionsPopup(true);
  };

  const onEditDateClick = async (cellIdentifier: CellIdentifier, left: number, top: number) => {
    setEditingCell(cellIdentifier);
    setDatePickerLeft(left);
    setDatePickerTop(top + 40);
    setShowDatePicker(true);
  };

  const onOpenOptionDetailClick = (_left: number, _top: number, _select_option: SelectOptionPB) => {
    setEditingSelectOption(_select_option);
    setShowEditCellOption(true);
    setEditCellOptionLeft(_left);
    setEditCellOptionTop(_top);
  };

  const onOpenCheckListDetailClick = (_left: number, _top: number, _select_option: SelectOptionPB) => {
    setEditingSelectOption(_select_option);
    setShowEditCheckList(true);
    setEditCheckListLeft(_left + 10);
    setEditCheckListTop(_top);
  };

  const onNumberFormat = (_left: number, _top: number) => {
    setShowNumberFormatPopup(true);
    setNumberFormatLeft(_left + 10);
    setNumberFormatTop(_top);
  };

  const onEditCheckListClick = (cellIdentifier: CellIdentifier, left: number, top: number) => {
    setEditingCell(cellIdentifier);
    setShowCheckListPopup(true);
    setCheckListPopupLeft(left);
    setCheckListPopupTop(top + 40);
  };

  const onDragEnd: OnDragEndResponder = (result) => {
    if (!result.destination?.index) return;
    void controller.moveField({
      fieldId: result.draggableId,
      fromIndex: result.source.index,
      toIndex: result.destination.index,
    });
  };

  const onDeletePropertyClick = (fieldId: string) => {
    setDeletingPropertyId(fieldId);
    setShowDeletePropertyPrompt(true);
  };

  const onDelete = async () => {
    if (!deletingPropertyId) return;
    const fieldInfo = controller.fieldController.getField(deletingPropertyId);
    if (!fieldInfo) return;
    const typeController = new TypeOptionController(viewId, Some(fieldInfo));
    await typeController.initialize();
    await typeController.deleteField();
    setShowDeletePropertyPrompt(false);
  };

  return (
    <>
      <div
        className={`fixed inset-0 z-10 flex items-center justify-center bg-black/30 backdrop-blur-sm transition-opacity duration-300 ${
          unveil ? 'opacity-100' : 'opacity-0'
        }`}
        onClick={() => onCloseClick()}
      >
        <div
          onClick={(e) => {
            e.stopPropagation();
          }}
          className={`relative flex h-[90%] w-[70%] flex-col gap-8 rounded-xl bg-white `}
        >
          <div onClick={() => onCloseClick()} className={'absolute top-1 right-1'}>
            <button className={'block h-8 w-8 rounded-lg text-shade-2 hover:bg-main-secondary'}>
              <CloseSvg></CloseSvg>
            </button>
          </div>

          <div className={'flex h-full'}>
            <div className={'flex h-full flex-1 flex-col border-r border-shade-6 pb-4 pt-6'}>
              <div className={'pl-12 pb-4'}>
                <button className={'flex items-center gap-2 p-4'}>
                  <i className={'h-5 w-5'}>
                    <ImageSvg></ImageSvg>
                  </i>
                  <span className={'text-xs'}>Add Cover</span>
                </button>
              </div>

              <DragDropContext onDragEnd={onDragEnd}>
                <Droppable droppableId={'field-list'}>
                  {(provided) => (
                    <div
                      {...provided.droppableProps}
                      ref={provided.innerRef}
                      className={`flex flex-1 flex-col gap-8 px-8 ${
                        showFieldEditor || showChangeOptionsPopup || showDatePicker ? 'overflow-hidden' : 'overflow-auto'
                      }`}
                    >
                      {cells
                        .filter((cell) => databaseStore.fields[cell.cellIdentifier.fieldId].visible)
                        .map((cell, cellIndex) => (
                          <EditCellWrapper
                            index={cellIndex}
                            key={cellIndex}
                            cellIdentifier={cell.cellIdentifier}
                            cellCache={controller.databaseViewCache.getRowCache().getCellCache()}
                            fieldController={controller.fieldController}
                            onEditFieldClick={onEditFieldClick}
                            onEditOptionsClick={onEditOptionsClick}
                            onEditDateClick={onEditDateClick}
                            onEditCheckListClick={onEditCheckListClick}
                          ></EditCellWrapper>
                        ))}
                    </div>
                  )}
                </Droppable>
              </DragDropContext>

              <div className={'border-t border-shade-6 px-8 pt-2'}>
                <button
                  onClick={() => onNewColumnClick()}
                  className={'flex w-full items-center gap-2 rounded-lg px-4 py-2 hover:bg-shade-6'}
                >
                  <i className={'h-5 w-5'}>
                    <AddSvg></AddSvg>
                  </i>
                  <span>{t('grid.field.newProperty')}</span>
                </button>
              </div>
            </div>
            <PropertiesPanel
              viewId={viewId}
              controller={controller}
              rowInfo={rowInfo}
              onDeletePropertyClick={onDeletePropertyClick}
              onNewColumnClick={onNewColumnClick}
            ></PropertiesPanel>
          </div>

          {showFieldEditor && editingCell && (
            <EditFieldPopup
              top={editFieldTop}
              left={editFieldLeft}
              cellIdentifier={editingCell}
              viewId={viewId}
              onOutsideClick={onOutsideEditFieldClick}
              fieldInfo={controller.fieldController.getField(editingCell.fieldId)}
              fieldController={controller.fieldController}
              changeFieldTypeClick={onChangeFieldTypeClick}
              onNumberFormat={onNumberFormat}
            ></EditFieldPopup>
          )}
          {showChangeFieldTypePopup && (
            <ChangeFieldTypePopup
              top={changeFieldTypeTop}
              left={changeFieldTypeLeft}
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
              onOutsideClick={() => !showEditCellOption && setShowChangeOptionsPopup(false)}
              openOptionDetail={onOpenOptionDetailClick}
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
          {showEditCellOption && editingCell && editingSelectOption && (
            <EditCellOptionPopup
              top={editCellOptionTop}
              left={editCellOptionLeft}
              cellIdentifier={editingCell}
              editingSelectOption={editingSelectOption}
              onOutsideClick={() => {
                setShowEditCellOption(false);
              }}
            ></EditCellOptionPopup>
          )}
          {showNumberFormatPopup && editingCell && (
            <NumberFormatPopup
              top={numberFormatTop}
              left={numberFormatLeft}
              cellIdentifier={editingCell}
              fieldController={controller.fieldController}
              onOutsideClick={() => {
                setShowNumberFormatPopup(false);
              }}
            ></NumberFormatPopup>
          )}
          {showCheckListPopup && editingCell && (
            <CheckListPopup
              top={checkListPopupTop}
              left={checkListPopupLeft}
              cellIdentifier={editingCell}
              cellCache={controller.databaseViewCache.getRowCache().getCellCache()}
              fieldController={controller.fieldController}
              onOutsideClick={() => !showEditCheckList && setShowCheckListPopup(false)}
              openCheckListDetail={onOpenCheckListDetailClick}
            ></CheckListPopup>
          )}
          {showEditCheckList && editingCell && editingSelectOption && (
            <EditCheckListPopup
              top={editCheckListTop}
              left={editCheckListLeft}
              cellIdentifier={editingCell}
              editingSelectOption={editingSelectOption}
              onOutsideClick={() => setShowEditCheckList(false)}
            ></EditCheckListPopup>
          )}
        </div>
      </div>
      {showDeletePropertyPrompt && (
        <PromptWindow
          msg={'Are you sure you want to delete this property?'}
          onYes={() => onDelete()}
          onCancel={() => setShowDeletePropertyPrompt(false)}
        ></PromptWindow>
      )}
    </>
  );
};
