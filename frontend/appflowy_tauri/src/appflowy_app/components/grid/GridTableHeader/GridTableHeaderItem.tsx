import { CellIdentifier } from '@/appflowy_app/stores/effects/database/cell/cell_bd_svc';
import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';
import { TypeOptionController } from '@/appflowy_app/stores/effects/database/field/type_option/type_option_controller';
import { FieldType } from '@/services/backend';
import { useState, useRef } from 'react';
import { Some } from 'ts-results';
import { ChangeFieldTypePopup } from '../../_shared/EditRow/ChangeFieldTypePopup';
import { EditFieldPopup } from '../../_shared/EditRow/EditFieldPopup';
import { ChecklistTypeSvg } from '../../_shared/svg/ChecklistTypeSvg';
import { DateTypeSvg } from '../../_shared/svg/DateTypeSvg';
import { MultiSelectTypeSvg } from '../../_shared/svg/MultiSelectTypeSvg';
import { NumberTypeSvg } from '../../_shared/svg/NumberTypeSvg';
import { SingleSelectTypeSvg } from '../../_shared/svg/SingleSelectTypeSvg';
import { TextTypeSvg } from '../../_shared/svg/TextTypeSvg';
import { UrlTypeSvg } from '../../_shared/svg/UrlTypeSvg';

export const GridTableHeaderItem = ({
  controller,
  field,
}: {
  controller: DatabaseController;
  field: {
    fieldId: string;
    name: string;
    fieldType: FieldType;
  };
}) => {
  const [showFieldEditor, setShowFieldEditor] = useState(false);
  const [editFieldTop, setEditFieldTop] = useState(0);
  const [editFieldRight, setEditFieldRight] = useState(0);

  const [showChangeFieldTypePopup, setShowChangeFieldTypePopup] = useState(false);
  const [changeFieldTypeTop, setChangeFieldTypeTop] = useState(0);
  const [changeFieldTypeRight, setChangeFieldTypeRight] = useState(0);

  const [editingField, setEditingField] = useState<{
    fieldId: string;
    name: string;
    fieldType: FieldType;
  } | null>(null);

  const ref = useRef<HTMLDivElement>(null);

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
    <th key={field.fieldId} className='m-0 border border-l-0 border-shade-6  p-0'>
      <div
        className={'flex w-full cursor-pointer items-center px-4 py-2 hover:bg-main-secondary'}
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
        <i className={'mr-2 h-5 w-5 text-shade-3'}>
          {field.fieldType === FieldType.RichText && <TextTypeSvg></TextTypeSvg>}
          {field.fieldType === FieldType.Number && <NumberTypeSvg></NumberTypeSvg>}
          {field.fieldType === FieldType.DateTime && <DateTypeSvg></DateTypeSvg>}
          {field.fieldType === FieldType.SingleSelect && <SingleSelectTypeSvg></SingleSelectTypeSvg>}
          {field.fieldType === FieldType.MultiSelect && <MultiSelectTypeSvg></MultiSelectTypeSvg>}
          {field.fieldType === FieldType.Checklist && <ChecklistTypeSvg></ChecklistTypeSvg>}
          {field.fieldType === FieldType.Checkbox && <ChecklistTypeSvg></ChecklistTypeSvg>}
          {field.fieldType === FieldType.URL && <UrlTypeSvg></UrlTypeSvg>}
        </i>
        <span>{field.name}</span>

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
            fieldInfo={controller.fieldController.getField(editingField.fieldId)}
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
    </th>
  );
};
