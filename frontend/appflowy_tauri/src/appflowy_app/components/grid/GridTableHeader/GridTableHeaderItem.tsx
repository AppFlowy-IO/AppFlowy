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
import { useAppDispatch } from '$app/stores/store';

export const GridTableHeaderItem = ({
  controller,
  field,
}: {
  controller: DatabaseController;
  field: IDatabaseField;
}) => {
  const { onMouseDown, newSizeX } = useResizer((final) => {
    void controller.changeWidth({ fieldId: field.fieldId, width: final });
  });
  const dispatch = useAppDispatch();
  const [showFieldEditor, setShowFieldEditor] = useState(false);
  const [editFieldTop, setEditFieldTop] = useState(0);
  const [editFieldRight, setEditFieldRight] = useState(0);

  const [showChangeFieldTypePopup, setShowChangeFieldTypePopup] = useState(false);
  const [changeFieldTypeTop, setChangeFieldTypeTop] = useState(0);
  const [changeFieldTypeRight, setChangeFieldTypeRight] = useState(0);

  const [editingField, setEditingField] = useState<IDatabaseField | null>(null);

  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!newSizeX) return;
    dispatch(databaseActions.changeWidth({ fieldId: field.fieldId, width: newSizeX }));
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

  return (
    <>
      <div style={{ width: `${field.width}px` }} className='flex-shrink-0 border-b border-t border-shade-6'>
        <div
          className={'flex w-full cursor-pointer items-center gap-2 px-4 py-2 hover:bg-main-secondary'}
          ref={ref}
          onClick={() => {
            if (!ref.current) return;
            const { top, left } = ref.current.getBoundingClientRect();

            setEditFieldRight(left - 10);
            setEditFieldTop(top + 35);
            setEditingField(field);
            setShowFieldEditor(true);
          }}
        >
          <div className={'flex h-5 w-5 flex-shrink-0 items-center justify-center text-shade-3'}>
            <FieldTypeIcon fieldType={field.fieldType}></FieldTypeIcon>
          </div>
          <span className={'overflow-hidden text-ellipsis whitespace-nowrap text-shade-3'}>{field.title}</span>

          {showFieldEditor && editingField && (
            <EditFieldPopup
              top={editFieldTop}
              left={editFieldRight}
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
              changeFieldTypeClick={(buttonTop, buttonRight) => {
                setChangeFieldTypeTop(buttonTop);
                setChangeFieldTypeRight(buttonRight);
                setShowChangeFieldTypePopup(true);
              }}
            ></EditFieldPopup>
          )}

          {showChangeFieldTypePopup && (
            <ChangeFieldTypePopup
              top={changeFieldTypeTop}
              left={changeFieldTypeRight}
              onClick={(newType) => changeFieldType(newType)}
              onOutsideClick={() => setShowChangeFieldTypePopup(false)}
            ></ChangeFieldTypePopup>
          )}
        </div>
      </div>
      <div
        className={'group z-[1] -mx-[10px] h-full cursor-col-resize px-[6px]'}
        onMouseDown={(e) => onMouseDown(e, field.width)}
      >
        <div className={'flex h-full w-[3px] justify-center group-hover:bg-main-accent'}>
          <div className={'h-full w-[1px] bg-shade-6 group-hover:bg-main-accent'}></div>
        </div>
      </div>
    </>
  );
};
