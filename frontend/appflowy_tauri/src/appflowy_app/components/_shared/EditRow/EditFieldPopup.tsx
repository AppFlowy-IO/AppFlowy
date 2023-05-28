import { FocusEventHandler, MouseEventHandler, useEffect, useRef, useState } from 'react';
import { FieldTypeIcon } from '$app/components/_shared/EditRow/FieldTypeIcon';
import { FieldTypeName } from '$app/components/_shared/EditRow/FieldTypeName';
import { useTranslation } from 'react-i18next';
import { TypeOptionController } from '$app/stores/effects/database/field/type_option/type_option_controller';
import { Some } from 'ts-results';
import { FieldController, FieldInfo } from '$app/stores/effects/database/field/field_controller';
import { MoreSvg } from '$app/components/_shared/svg/MoreSvg';
import { useAppSelector } from '$app/stores/store';
import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { PopupWindow } from '$app/components/_shared/PopupWindow';
import { FieldType } from '@/services/backend';
import { DateTypeOptions } from '$app/components/_shared/EditRow/Date/DateTypeOptions';

export const EditFieldPopup = ({
  top,
  left,
  cellIdentifier,
  viewId,
  onOutsideClick,
  fieldInfo,
  fieldController,
  changeFieldTypeClick,
  onNumberFormat,
}: {
  top: number;
  left: number;
  cellIdentifier: CellIdentifier;
  viewId: string;
  onOutsideClick: () => void;
  fieldInfo: FieldInfo | undefined;
  fieldController?: FieldController;
  changeFieldTypeClick: (buttonTop: number, buttonRight: number) => void;
  onNumberFormat?: (buttonLeft: number, buttonTop: number) => void;
}) => {
  const databaseStore = useAppSelector((state) => state.database);
  const { t } = useTranslation();
  const changeTypeButtonRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const [name, setName] = useState('');

  useEffect(() => {
    setName(databaseStore.fields[cellIdentifier.fieldId].title);
  }, [databaseStore, cellIdentifier]);

  // focus input on mount
  useEffect(() => {
    if (!inputRef.current || !name) return;
    inputRef.current.focus();
  }, [inputRef, name]);

  const selectAll: FocusEventHandler<HTMLInputElement> = (e) => {
    e.target.selectionStart = 0;
    e.target.selectionEnd = e.target.value.length;
  };

  const save = async () => {
    if (!fieldInfo) return;
    const controller = new TypeOptionController(viewId, Some(fieldInfo));
    await controller.initialize();
    await controller.setFieldName(name);
  };

  const onChangeFieldTypeClick = () => {
    if (!changeTypeButtonRef.current) return;
    const { top: buttonTop, right: buttonRight } = changeTypeButtonRef.current.getBoundingClientRect();
    changeFieldTypeClick(buttonTop, buttonRight);
  };

  const onNumberFormatClick: MouseEventHandler = (e) => {
    e.stopPropagation();
    let target = e.target as HTMLElement;

    while (!(target instanceof HTMLButtonElement)) {
      if (target.parentElement === null) return;
      target = target.parentElement;
    }

    const { right: _left, top: _top } = target.getBoundingClientRect();
    onNumberFormat?.(_left, _top);
  };

  return (
    <PopupWindow
      className={'px-2 py-2 text-xs'}
      onOutsideClick={async () => {
        await save();
        onOutsideClick();
      }}
      left={left}
      top={top}
    >
      <div className={'flex flex-col gap-2'}>
        <input
          ref={inputRef}
          onFocus={selectAll}
          value={name}
          onChange={(e) => setName(e.target.value)}
          onBlur={() => save()}
          className={'border-shades-3 flex-1 rounded border bg-main-selector px-2 py-2'}
        />

        <div
          ref={changeTypeButtonRef}
          onClick={() => onChangeFieldTypeClick()}
          className={
            'relative flex cursor-pointer items-center justify-between rounded-lg py-2 text-black hover:bg-main-secondary'
          }
        >
          <button className={'flex cursor-pointer items-center gap-2 rounded-lg pl-2'}>
            <i className={'h-5 w-5'}>
              <FieldTypeIcon fieldType={cellIdentifier.fieldType}></FieldTypeIcon>
            </i>
            <span>
              <FieldTypeName fieldType={cellIdentifier.fieldType}></FieldTypeName>
            </span>
          </button>
          <span className={'pr-2'}>
            <i className={' block h-5 w-5'}>
              <MoreSvg></MoreSvg>
            </i>
          </span>
        </div>

        {cellIdentifier.fieldType === FieldType.Number && (
          <>
            <hr className={'-mx-2 border-shade-6'} />
            <button
              onClick={onNumberFormatClick}
              className={
                'flex w-full cursor-pointer items-center justify-between rounded-lg py-2 hover:bg-main-secondary'
              }
            >
              <span className={'pl-2'}>{t('grid.field.numberFormat')}</span>
              <span className={'pr-2'}>
                <i className={'block h-5 w-5'}>
                  <MoreSvg></MoreSvg>
                </i>
              </span>
            </button>
          </>
        )}

        {cellIdentifier.fieldType === FieldType.DateTime && fieldController && (
          <DateTypeOptions cellIdentifier={cellIdentifier} fieldController={fieldController}></DateTypeOptions>
        )}
      </div>
    </PopupWindow>
  );
};
