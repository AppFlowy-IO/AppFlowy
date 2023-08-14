import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { KeyboardEventHandler, useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { SelectOptionColorPB, SelectOptionPB } from '@/services/backend';
import { getBgColor } from '$app/components/_shared/getColor';
import { SelectOptionCellBackendService } from '$app/stores/effects/database/cell/select_option_bd_svc';
import { TrashSvg } from '$app/components/_shared/svg/TrashSvg';
import { CheckmarkSvg } from '$app/components/_shared/svg/CheckmarkSvg';
import { PopupWindow } from '$app/components/_shared/PopupWindow';
import { databaseActions, ISelectOptionType } from '$app_reducers/database/slice';
import { useAppDispatch, useAppSelector } from '$app/stores/store';

export const EditCellOptionPopup = ({
  left,
  top,
  cellIdentifier,
  editingSelectOption,
  setEditingSelectOption,
  onOutsideClick,
}: {
  left: number;
  top: number;
  cellIdentifier: CellIdentifier;
  editingSelectOption: SelectOptionPB;
  setEditingSelectOption: (option: SelectOptionPB) => void;
  onOutsideClick: () => void;
}) => {
  const inputRef = useRef<HTMLInputElement>(null);
  const { t } = useTranslation();
  const [value, setValue] = useState('');
  const fieldsStore = useAppSelector((state) => state.database.fields);
  const dispatch = useAppDispatch();

  useEffect(() => {
    setValue(editingSelectOption.name);
  }, [editingSelectOption]);

  const onKeyDown: KeyboardEventHandler = async (e) => {
    if (e.key === 'Enter' && value.length > 0) {
      await new SelectOptionCellBackendService(cellIdentifier).createOption({ name: value });
      setValue('');
    }
  };

  const onKeyDownWrapper: KeyboardEventHandler = (e) => {
    if (e.key === 'Escape') {
      onOutsideClick();
    }
  };

  const onBlur = async () => {
    const svc = new SelectOptionCellBackendService(cellIdentifier);

    await svc.updateOption(
      new SelectOptionPB({
        id: editingSelectOption.id,
        color: editingSelectOption.color,
        name: value,
      })
    );
  };

  const onUpdateSelectOption = (option: SelectOptionPB) => {
    const updatingField = fieldsStore[cellIdentifier.fieldId];
    const allOptions = (updatingField.fieldOptions as ISelectOptionType).selectOptions;

    dispatch(
      databaseActions.updateField({
        field: {
          ...updatingField,
          fieldOptions: {
            selectOptions: allOptions.map((o) =>
              o.selectOptionId === option.id
                ? {
                    selectOptionId: option.id,
                    color: option.color,
                    title: option.name,
                  }
                : o
            ),
          },
        },
      })
    );

    setEditingSelectOption(option);
  };

  const onColorClick = async (color: SelectOptionColorPB) => {
    const svc = new SelectOptionCellBackendService(cellIdentifier);

    const updatedOption = new SelectOptionPB({
      id: editingSelectOption.id,
      color,
      name: editingSelectOption.name,
    });

    await svc.updateOption(updatedOption);
    onUpdateSelectOption(updatedOption);
  };

  const onDeleteOptionClick = async () => {
    const svc = new SelectOptionCellBackendService(cellIdentifier);

    await svc.deleteOption([editingSelectOption]);
    onOutsideClick();
  };

  return (
    <PopupWindow
      className={'p-2 text-xs'}
      onOutsideClick={async () => {
        await onBlur();
        onOutsideClick();
      }}
      left={left}
      top={top}
    >
      <div onKeyDown={onKeyDownWrapper} className={'flex flex-col gap-2 p-2'}>
        <div
          className={
            'flex flex-1 items-center gap-2 rounded border border-line-divider px-2 hover:border-fill-hover focus:border-fill-hover'
          }
        >
          <input
            ref={inputRef}
            className={'py-2'}
            value={value}
            onChange={(e) => setValue(e.target.value)}
            onKeyDown={onKeyDown}
            onBlur={() => onBlur()}
          />
          <div className={'font-mono text-text-caption'}>{value.length}/30</div>
        </div>
        <button
          onClick={() => onDeleteOptionClick()}
          className={
            'text-main-alert flex cursor-pointer items-center gap-2 rounded-lg px-2 py-2 hover:bg-fill-list-hover'
          }
        >
          <i className={'h-5 w-5'}>
            <TrashSvg></TrashSvg>
          </i>
          <span>{t('grid.selectOption.deleteTag')}</span>
        </button>
        <div className={'-mx-4 h-[1px] bg-line-divider'}></div>
        <div className={'my-2 font-medium text-text-caption'}>{t('grid.selectOption.colorPanelTitle')}</div>
        <div className={'flex flex-col'}>
          <ColorItem
            title={t('grid.selectOption.purpleColor')}
            onClick={() => onColorClick(SelectOptionColorPB.Purple)}
            bgColor={getBgColor(SelectOptionColorPB.Purple)}
            checked={editingSelectOption.color === SelectOptionColorPB.Purple}
          ></ColorItem>
          <ColorItem
            title={t('grid.selectOption.pinkColor')}
            onClick={() => onColorClick(SelectOptionColorPB.Pink)}
            bgColor={getBgColor(SelectOptionColorPB.Pink)}
            checked={editingSelectOption.color === SelectOptionColorPB.Pink}
          ></ColorItem>
          <ColorItem
            title={t('grid.selectOption.lightPinkColor')}
            onClick={() => onColorClick(SelectOptionColorPB.LightPink)}
            bgColor={getBgColor(SelectOptionColorPB.LightPink)}
            checked={editingSelectOption.color === SelectOptionColorPB.LightPink}
          ></ColorItem>
          <ColorItem
            title={t('grid.selectOption.orangeColor')}
            onClick={() => onColorClick(SelectOptionColorPB.Orange)}
            bgColor={getBgColor(SelectOptionColorPB.Orange)}
            checked={editingSelectOption.color === SelectOptionColorPB.Orange}
          ></ColorItem>
          <ColorItem
            title={t('grid.selectOption.yellowColor')}
            onClick={() => onColorClick(SelectOptionColorPB.Yellow)}
            bgColor={getBgColor(SelectOptionColorPB.Yellow)}
            checked={editingSelectOption.color === SelectOptionColorPB.Yellow}
          ></ColorItem>
          <ColorItem
            title={t('grid.selectOption.limeColor')}
            onClick={() => onColorClick(SelectOptionColorPB.Lime)}
            bgColor={getBgColor(SelectOptionColorPB.Lime)}
            checked={editingSelectOption.color === SelectOptionColorPB.Lime}
          ></ColorItem>
          <ColorItem
            title={t('grid.selectOption.greenColor')}
            onClick={() => onColorClick(SelectOptionColorPB.Green)}
            bgColor={getBgColor(SelectOptionColorPB.Green)}
            checked={editingSelectOption.color === SelectOptionColorPB.Green}
          ></ColorItem>
          <ColorItem
            title={t('grid.selectOption.aquaColor')}
            onClick={() => onColorClick(SelectOptionColorPB.Aqua)}
            bgColor={getBgColor(SelectOptionColorPB.Aqua)}
            checked={editingSelectOption.color === SelectOptionColorPB.Aqua}
          ></ColorItem>
          <ColorItem
            title={t('grid.selectOption.blueColor')}
            onClick={() => onColorClick(SelectOptionColorPB.Blue)}
            bgColor={getBgColor(SelectOptionColorPB.Blue)}
            checked={editingSelectOption.color === SelectOptionColorPB.Blue}
          ></ColorItem>
        </div>
      </div>
    </PopupWindow>
  );
};

const ColorItem = ({
  title,
  bgColor,
  onClick,
  checked,
}: {
  title: string;
  bgColor: string;
  onClick: () => void;
  checked: boolean;
}) => {
  return (
    <div
      className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-fill-list-hover'}
      onClick={() => onClick()}
    >
      <div className={'flex items-center gap-2'}>
        <div className={`h-4 w-4 rounded-full ${bgColor}`}></div>
        <span>{title}</span>
      </div>
      {checked && (
        <i className={'block h-3 w-3'}>
          <CheckmarkSvg></CheckmarkSvg>
        </i>
      )}
    </div>
  );
};
