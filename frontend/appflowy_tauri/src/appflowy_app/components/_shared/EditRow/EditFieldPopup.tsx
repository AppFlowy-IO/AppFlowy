import { useEffect, useRef, useState } from 'react';
import useOutsideClick from '$app/components/_shared/useOutsideClick';
import { TrashSvg } from '$app/components/_shared/svg/TrashSvg';
import { CellController } from '$app/stores/effects/database/cell/cell_controller';
import { FieldType } from '@/services/backend';
import { FieldTypeIcon } from '$app/components/_shared/EditRow/FieldTypeIcon';
import { FieldTypeName } from '$app/components/_shared/EditRow/FieldTypeName';
import { useTranslation } from 'react-i18next';
import { TypeOptionController } from '$app/stores/effects/database/field/type_option/type_option_controller';
import { Some } from 'ts-results';
import { FieldInfo } from '$app/stores/effects/database/field/field_controller';

export const EditFieldPopup = ({
  viewId,
  fieldName,
  onOutsideClick,
  fieldType,
  cellController,
  fieldInfo,
}: {
  viewId: string;
  fieldName: string;
  onOutsideClick?: () => void;
  fieldType: FieldType;
  cellController: CellController<any, any>;
  fieldInfo: FieldInfo | undefined;
}) => {
  const { t } = useTranslation('');
  const ref = useRef<HTMLDivElement>(null);
  const [name, setName] = useState('');
  useOutsideClick(ref, async () => {
    await save();
    onOutsideClick && onOutsideClick();
  });

  useEffect(() => {
    setName(fieldName);
  }, [fieldName]);

  const save = async () => {
    if (!fieldInfo) return;
    const controller = new TypeOptionController(viewId, Some(fieldInfo));
    await controller.initialize();
    await controller.setFieldName(name);
  };

  return (
    <div ref={ref} className={`absolute left-full top-0 rounded-lg bg-white px-2 py-2 shadow-md`}>
      <div className={'flex flex-col gap-4 p-4'}>
        <input
          value={name}
          onChange={(e) => setName(e.target.value)}
          onBlur={() => save()}
          className={'border-shades-3 flex-1 rounded border bg-main-selector p-1'}
        />
        <button
          className={
            'flex cursor-pointer items-center gap-2 rounded-lg px-2 py-2 text-main-alert hover:bg-main-secondary'
          }
        >
          <i className={'mb-0.5 h-5 w-5'}>
            <TrashSvg></TrashSvg>
          </i>
          <span>{t('grid.field.delete')}</span>
        </button>

        <button
          className={'flex cursor-pointer items-center gap-2 rounded-lg px-2 py-2 text-black hover:bg-main-secondary'}
        >
          <i className={'h-5 w-5'}>
            <FieldTypeIcon fieldType={fieldType}></FieldTypeIcon>
          </i>
          <span>
            <FieldTypeName fieldType={fieldType}></FieldTypeName>
          </span>
        </button>
      </div>
    </div>
  );
};
