import React, { FocusEventHandler, useEffect, useRef, useState } from 'react';
import { FieldTypeIcon } from '$app/components/_shared/EditRow/FieldTypeIcon';
import { FieldTypeName } from '$app/components/_shared/EditRow/FieldTypeName';
import { useTranslation } from 'react-i18next';
import { TypeOptionController } from '$app/stores/effects/database/field/type_option/type_option_controller';
import { Some } from 'ts-results';
import { MoreSvg } from '$app/components/_shared/svg/MoreSvg';
import { useAppSelector } from '$app/stores/store';
import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { DatabaseController } from '$app/stores/effects/database/database_controller';
import { EyeClosedSvg } from '$app/components/_shared/svg/EyeClosedSvg';
import { Popover } from '@mui/material';
import { CopySvg } from '$app/components/_shared/svg/CopySvg';
import { TrashSvg } from '$app/components/_shared/svg/TrashSvg';
import { SkipLeftSvg } from '$app/components/_shared/svg/SkipLeftSvg';
import { SkipRightSvg } from '$app/components/_shared/svg/SkipRightSvg';
import { EyeOpenSvg } from '$app/components/_shared/svg/EyeOpenSvg';

export const EditFieldPopup = ({
  open,
  anchorEl,
  cellIdentifier,
  viewId,
  onOutsideClick,
  controller,
  changeFieldTypeClick,
  onDeletePropertyClick,
}: {
  open: boolean;
  anchorEl: HTMLDivElement | null;
  cellIdentifier: CellIdentifier;
  viewId: string;
  onOutsideClick: () => void;
  controller: DatabaseController;
  changeFieldTypeClick: (el: HTMLDivElement) => void;
  onDeletePropertyClick: (fieldId: string) => void;
}) => {
  const fieldsStore = useAppSelector((state) => state.database.fields);
  const { t } = useTranslation();
  const changeTypeButtonRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const [name, setName] = useState('');

  useEffect(() => {
    setName(fieldsStore[cellIdentifier.fieldId].title);
  }, [fieldsStore, cellIdentifier]);

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
    if (!controller) return;
    const fieldInfo = controller.fieldController.getField(cellIdentifier.fieldId);
    if (!fieldInfo) return;
    const typeOptionController = new TypeOptionController(viewId, Some(fieldInfo));

    await typeOptionController.initialize();
    await typeOptionController.setFieldName(name);
  };

  const onChangeFieldTypeClick = () => {
    if (!changeTypeButtonRef.current) return;

    changeFieldTypeClick(changeTypeButtonRef.current);
  };

  const toggleHideProperty = async () => {
    // we need to close the popup because after hiding the field, parent element will be removed
    onOutsideClick();
    const fieldInfo = controller.fieldController.getField(cellIdentifier.fieldId);

    if (fieldInfo) {
      const typeController = new TypeOptionController(viewId, Some(fieldInfo));

      await typeController.initialize();
      if (fieldInfo.field.visibility) {
        await typeController.hideField();
      } else {
        await typeController.showField();
      }
    }
  };

  const onDuplicatePropertyClick = async () => {
    onOutsideClick();
    await controller.duplicateField(cellIdentifier.fieldId);
  };

  const onAddToLeftClick = async () => {
    onOutsideClick();
    await controller.addFieldToLeft(cellIdentifier.fieldId);
  };

  const onAddToRightClick = async () => {
    onOutsideClick();
    await controller.addFieldToRight(cellIdentifier.fieldId);
  };

  return (
    <Popover
      anchorEl={anchorEl}
      open={open}
      onClose={async () => {
        await save();
        onOutsideClick();
      }}
      anchorOrigin={{
        vertical: 'bottom',
        horizontal: 'left',
      }}
      transformOrigin={{
        vertical: 'top',
        horizontal: 'left',
      }}
    >
      <div className={'flex flex-col gap-2 p-2 text-xs'}>
        <input
          ref={inputRef}
          onFocus={selectAll}
          value={name}
          onChange={(e) => setName(e.target.value)}
          onBlur={() => save()}
          className={
            'flex-1 rounded border border-line-divider px-2 py-2 hover:border-fill-default focus:border-fill-default'
          }
        />

        <div
          ref={changeTypeButtonRef}
          onClick={() => onChangeFieldTypeClick()}
          className={
            'relative flex cursor-pointer items-center justify-between rounded-lg py-2 text-text-title hover:bg-fill-list-hover'
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

        <div className={'-mx-2 h-[1px] bg-line-divider'}></div>

        <div className={'grid grid-cols-2'}>
          <div className={'flex flex-col gap-2'}>
            <div
              onClick={toggleHideProperty}
              className={'flex cursor-pointer items-center gap-2 rounded-lg p-2 pr-8 hover:bg-fill-list-hover'}
            >
              {fieldsStore[cellIdentifier.fieldId]?.visible ? (
                <>
                  <i className={'block h-5 w-5'}>
                    <EyeClosedSvg />
                  </i>
                  <span>{t('grid.field.hide')}</span>
                </>
              ) : (
                <>
                  <i className={'block h-5 w-5'}>
                    <EyeOpenSvg />
                  </i>
                  <span>Show</span>
                </>
              )}
            </div>
            <div
              onClick={() => onDuplicatePropertyClick()}
              className={'flex cursor-pointer items-center gap-2 rounded-lg p-2 pr-8 hover:bg-fill-list-hover'}
            >
              <i className={'block h-5 w-5'}>
                <CopySvg />
              </i>
              <span>{t('grid.field.duplicate')}</span>
            </div>
            <div
              onClick={() => {
                onOutsideClick();
                onDeletePropertyClick(cellIdentifier.fieldId);
              }}
              className={'flex cursor-pointer items-center gap-2 rounded-lg p-2 pr-8 hover:bg-fill-list-hover'}
            >
              <i className={'block h-5 w-5'}>
                <TrashSvg />
              </i>
              <span>{t('grid.field.delete')}</span>
            </div>
          </div>

          <div className={'flex flex-col gap-2'}>
            <div
              onClick={onAddToLeftClick}
              className={'flex cursor-pointer items-center gap-2 rounded-lg p-2 pr-8 hover:bg-fill-list-hover'}
            >
              <i className={'block h-5 w-5'}>
                <SkipLeftSvg />
              </i>
              <span>{t('grid.field.insertLeft')}</span>
            </div>
            <div
              onClick={onAddToRightClick}
              className={'flex cursor-pointer items-center gap-2 rounded-lg p-2 pr-8 hover:bg-fill-list-hover'}
            >
              <i className={'block h-5 w-5'}>
                <SkipRightSvg />
              </i>
              <span>{t('grid.field.insertRight')}</span>
            </div>
          </div>
        </div>
      </div>
    </Popover>
  );
};
