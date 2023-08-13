import { CellIdentifier } from '@/appflowy_app/stores/effects/database/cell/cell_bd_svc';
import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';
import { TypeOptionController } from '@/appflowy_app/stores/effects/database/field/type_option/type_option_controller';
import { FieldType } from '@/services/backend';
import { useState, useRef, useEffect } from 'react';
import { Some } from 'ts-results';
import { ChangeFieldTypePopup } from '../../_shared/EditRow/ChangeFieldTypePopup';
import { EditFieldPopup } from '../../_shared/EditRow/EditFieldPopup';
import { databaseActions, IDatabaseField } from '$app_reducers/database/slice';
import { FieldTypeIcon } from '$app/components/_shared/EditRow/FieldTypeIcon';
import { useResizer } from '$app/components/_shared/useResizer';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { Details2Svg } from '$app/components/_shared/svg/Details2Svg';
import { FilterSvg } from '$app/components/_shared/svg/FilterSvg';
import { SortAscSvg } from '$app/components/_shared/svg/SortAscSvg';
import { PromptWindow } from '$app/components/_shared/PromptWindow';

const MIN_COLUMN_WIDTH = 100;

export const GridTableHeaderItem = ({
  controller,
  field,
  index,
  onShowFilterClick,
  onShowSortClick,
}: {
  controller: DatabaseController;
  field: IDatabaseField;
  index: number;
  onShowFilterClick: () => void;
  onShowSortClick: () => void;
}) => {
  const { onMouseDown, newSizeX } = useResizer((final) => {
    if (final < MIN_COLUMN_WIDTH) return;
    void controller.changeWidth({ fieldId: field.fieldId, width: final });
  });

  const filtersStore = useAppSelector((state) => state.database.filters);
  const sortStore = useAppSelector((state) => state.database.sort);

  const dispatch = useAppDispatch();
  const [showFieldEditor, setShowFieldEditor] = useState(false);
  const [showChangeFieldTypePopup, setShowChangeFieldTypePopup] = useState(false);
  const [changeFieldTypeAnchorEl, setChangeFieldTypeAnchorEl] = useState<HTMLDivElement | null>(null);
  const [editingField, setEditingField] = useState<IDatabaseField | null>(null);
  const [deletingPropertyId, setDeletingPropertyId] = useState<string | null>(null);
  const [showDeletePropertyPrompt, setShowDeletePropertyPrompt] = useState(false);

  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!newSizeX) return;
    if (newSizeX >= MIN_COLUMN_WIDTH) {
      dispatch(databaseActions.changeWidth({ fieldId: field.fieldId, width: newSizeX }));
    }
  }, [newSizeX]);

  const changeFieldType = async (newType: FieldType) => {
    if (!editingField) return;

    const currentField = controller.fieldController.getField(editingField.fieldId);

    if (!currentField) return;

    const typeOptionController = new TypeOptionController(controller.viewId, Some(currentField));

    await typeOptionController.switchToField(newType);

    setEditingField({
      ...editingField,
      fieldType: newType,
    });

    setShowChangeFieldTypePopup(false);
  };

  const onFieldOptionsClick = () => {
    setEditingField(field);
    setShowFieldEditor(true);
  };

  const onDeletePropertyClick = (fieldId: string) => {
    setDeletingPropertyId(fieldId);
    setShowDeletePropertyPrompt(true);
  };

  const onDelete = async () => {
    if (!deletingPropertyId) return;
    const fieldInfo = controller.fieldController.getField(deletingPropertyId);

    if (!fieldInfo) return;
    const typeController = new TypeOptionController(controller.viewId, Some(fieldInfo));

    setEditingField(null);

    await typeController.initialize();
    await typeController.deleteField();
    setShowDeletePropertyPrompt(false);
  };

  return (
    <>
      <div
        // field width minus divider width with padding
        style={{ width: `${field.width - (index === 0 ? 7 : 14)}px` }}
        className='flex-shrink-0 border-b border-t border-line-divider'
      >
        <div className={'flex w-full items-center justify-between py-2 pl-2'} ref={ref}>
          <div className={'flex min-w-0 items-center gap-2'}>
            <div className={'flex h-5 w-5 flex-shrink-0 items-center justify-center text-text-caption'}>
              <FieldTypeIcon fieldType={field.fieldType}></FieldTypeIcon>
            </div>
            <span className={'overflow-hidden text-ellipsis whitespace-nowrap text-text-caption'}>{field.title}</span>
          </div>
          <div className={'flex items-center gap-1'}>
            {sortStore.findIndex((sort) => sort.fieldId === field.fieldId) !== -1 && (
              <button onClick={onShowSortClick} className={'rounded p-1 hover:bg-fill-list-hover'}>
                <i className={'block h-[16px] w-[16px]'}>
                  <SortAscSvg></SortAscSvg>
                </i>
              </button>
            )}

            {filtersStore.findIndex((filter) => filter.fieldId === field.fieldId) !== -1 && (
              <button onClick={onShowFilterClick} className={'rounded p-1 hover:bg-fill-list-hover'}>
                <i className={'block h-[16px] w-[16px]'}>
                  <FilterSvg></FilterSvg>
                </i>
              </button>
            )}

            <button className={'rounded p-1 hover:bg-fill-list-hover'} onClick={() => onFieldOptionsClick()}>
              <i className={'block h-[16px] w-[16px]'}>
                <Details2Svg></Details2Svg>
              </i>
            </button>
          </div>
        </div>
      </div>
      <div
        className={'group h-full cursor-col-resize border-b border-t border-line-divider px-[6px]'}
        onMouseDown={(e) => onMouseDown(e, field.width)}
      >
        <div className={'flex h-full w-[3px] justify-center group-hover:bg-fill-hover'}>
          <div className={'h-full w-[1px] bg-line-divider group-hover:bg-fill-hover'}></div>
        </div>
      </div>
      {editingField && (
        <EditFieldPopup
          open={showFieldEditor}
          anchorEl={ref.current}
          cellIdentifier={
            {
              fieldId: editingField.fieldId,
              fieldType: editingField.fieldType,
              viewId: controller.viewId,
            } as CellIdentifier
          }
          viewId={controller.viewId}
          onOutsideClick={() => {
            setShowFieldEditor(false);
          }}
          controller={controller}
          changeFieldTypeClick={(el) => {
            setChangeFieldTypeAnchorEl(el);
            setShowChangeFieldTypePopup(true);
          }}
          onDeletePropertyClick={onDeletePropertyClick}
        ></EditFieldPopup>
      )}

      <ChangeFieldTypePopup
        open={showChangeFieldTypePopup}
        anchorEl={changeFieldTypeAnchorEl}
        onClick={(newType) => changeFieldType(newType)}
        onOutsideClick={() => setShowChangeFieldTypePopup(false)}
      ></ChangeFieldTypePopup>

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
