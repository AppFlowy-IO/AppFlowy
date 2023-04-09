import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { KeyboardEventHandler, useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { SelectOptionColorPB, SelectOptionPB } from '@/services/backend';
import { getBgColor } from '$app/components/_shared/getColor';
import { SelectOptionCellBackendService } from '$app/stores/effects/database/cell/select_option_bd_svc';
import { TrashSvg } from '$app/components/_shared/svg/TrashSvg';
import { CheckmarkSvg } from '$app/components/_shared/svg/CheckmarkSvg';
import { PopupWindow } from '$app/components/_shared/PopupWindow';

export const EditCellOptionPopup = ({
  left,
  top,
  cellIdentifier,
  editingSelectOption,
  onOutsideClick,
}: {
  left: number;
  top: number;
  cellIdentifier: CellIdentifier;
  editingSelectOption: SelectOptionPB;
  onOutsideClick: () => void;
}) => {
  const inputRef = useRef<HTMLInputElement>(null);
  const { t } = useTranslation('');
  const [value, setValue] = useState('');

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

  const onColorClick = async (color: SelectOptionColorPB) => {
    const svc = new SelectOptionCellBackendService(cellIdentifier);
    await svc.updateOption(
      new SelectOptionPB({
        id: editingSelectOption.id,
        color,
        name: editingSelectOption.name,
      })
    );
  };

  const onDeleteOptionClick = async () => {
    const svc = new SelectOptionCellBackendService(cellIdentifier);
    await svc.deleteOption([editingSelectOption]);
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
        <div className={'border-shades-3 flex flex-1 items-center gap-2 rounded border bg-main-selector px-2 '}>
          <input
            ref={inputRef}
            className={'py-2'}
            value={value}
            onChange={(e) => setValue(e.target.value)}
            onKeyDown={onKeyDown}
            onBlur={() => onBlur()}
          />
          <div className={'font-mono text-shade-3'}>{value.length}/30</div>
        </div>
        <button
          onClick={() => onDeleteOptionClick()}
          className={
            'flex cursor-pointer items-center gap-2 rounded-lg px-2 py-2 text-main-alert hover:bg-main-secondary'
          }
        >
          <i className={'h-5 w-5'}>
            <TrashSvg></TrashSvg>
          </i>
          <span>{t('grid.selectOption.deleteTag')}</span>
        </button>
        <div className={'-mx-4 h-[1px] bg-shade-6'}></div>
        <div className={'my-2 font-medium text-shade-3'}>{t('grid.selectOption.colorPanelTitle')}</div>
        <div className={'flex flex-col'}>
          <div
            className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-main-secondary'}
            onClick={() => onColorClick(SelectOptionColorPB.Purple)}
          >
            <div className={'flex items-center gap-2'}>
              <div className={`h-4 w-4 rounded-full ${getBgColor(SelectOptionColorPB.Purple)}`}></div>
              <span>{t('grid.selectOption.purpleColor')}</span>
            </div>
            {editingSelectOption.color === SelectOptionColorPB.Purple && (
              <i className={'block h-3 w-3'}>
                <CheckmarkSvg></CheckmarkSvg>
              </i>
            )}
          </div>
          <div
            className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-main-secondary'}
            onClick={() => onColorClick(SelectOptionColorPB.Pink)}
          >
            <div className={'flex items-center gap-2'}>
              <div className={`h-4 w-4 rounded-full ${getBgColor(SelectOptionColorPB.Pink)}`}></div>
              <span>{t('grid.selectOption.pinkColor')}</span>
            </div>
            {editingSelectOption.color === SelectOptionColorPB.Pink && (
              <i className={'block h-3 w-3'}>
                <CheckmarkSvg></CheckmarkSvg>
              </i>
            )}
          </div>
          <div
            className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-main-secondary'}
            onClick={() => onColorClick(SelectOptionColorPB.LightPink)}
          >
            <div className={'flex items-center gap-2'}>
              <div className={`h-4 w-4 rounded-full ${getBgColor(SelectOptionColorPB.LightPink)}`}></div>
              <span>{t('grid.selectOption.lightPinkColor')}</span>
            </div>
            {editingSelectOption.color === SelectOptionColorPB.LightPink && (
              <i className={'block h-3 w-3'}>
                <CheckmarkSvg></CheckmarkSvg>
              </i>
            )}
          </div>
          <div
            className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-main-secondary'}
            onClick={() => onColorClick(SelectOptionColorPB.Orange)}
          >
            <div className={'flex items-center gap-2'}>
              <div className={`h-4 w-4 rounded-full ${getBgColor(SelectOptionColorPB.Orange)}`}></div>
              <span>{t('grid.selectOption.orangeColor')}</span>
            </div>
            {editingSelectOption.color === SelectOptionColorPB.Orange && (
              <i className={'block h-3 w-3'}>
                <CheckmarkSvg></CheckmarkSvg>
              </i>
            )}
          </div>
          <div
            className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-main-secondary'}
            onClick={() => onColorClick(SelectOptionColorPB.Yellow)}
          >
            <div className={'flex items-center gap-2'}>
              <div className={`h-4 w-4 rounded-full ${getBgColor(SelectOptionColorPB.Yellow)}`}></div>
              <span>{t('grid.selectOption.yellowColor')}</span>
            </div>
            {editingSelectOption.color === SelectOptionColorPB.Yellow && (
              <i className={'block h-3 w-3'}>
                <CheckmarkSvg></CheckmarkSvg>
              </i>
            )}
          </div>
          <div
            className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-main-secondary'}
            onClick={() => onColorClick(SelectOptionColorPB.Lime)}
          >
            <div className={'flex items-center gap-2'}>
              <div className={`h-4 w-4 rounded-full ${getBgColor(SelectOptionColorPB.Lime)}`}></div>
              <span>{t('grid.selectOption.limeColor')}</span>
            </div>
            {editingSelectOption.color === SelectOptionColorPB.Lime && (
              <i className={'block h-3 w-3'}>
                <CheckmarkSvg></CheckmarkSvg>
              </i>
            )}
          </div>
          <div
            className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-main-secondary'}
            onClick={() => onColorClick(SelectOptionColorPB.Green)}
          >
            <div className={'flex items-center gap-2'}>
              <div className={`h-4 w-4 rounded-full ${getBgColor(SelectOptionColorPB.Green)}`}></div>
              <span>{t('grid.selectOption.greenColor')}</span>
            </div>
            {editingSelectOption.color === SelectOptionColorPB.Green && (
              <i className={'block h-3 w-3'}>
                <CheckmarkSvg></CheckmarkSvg>
              </i>
            )}
          </div>
          <div
            className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-main-secondary'}
            onClick={() => onColorClick(SelectOptionColorPB.Aqua)}
          >
            <div className={'flex items-center gap-2'}>
              <div className={`h-4 w-4 rounded-full ${getBgColor(SelectOptionColorPB.Aqua)}`}></div>
              <span>{t('grid.selectOption.aquaColor')}</span>
            </div>
            {editingSelectOption.color === SelectOptionColorPB.Aqua && (
              <i className={'block h-3 w-3'}>
                <CheckmarkSvg></CheckmarkSvg>
              </i>
            )}
          </div>
          <div
            className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-main-secondary'}
            onClick={() => onColorClick(SelectOptionColorPB.Blue)}
          >
            <div className={'flex items-center gap-2'}>
              <div className={`h-4 w-4 rounded-full ${getBgColor(SelectOptionColorPB.Blue)}`}></div>
              <span>{t('grid.selectOption.blueColor')}</span>
            </div>
            {editingSelectOption.color === SelectOptionColorPB.Blue && (
              <i className={'block h-3 w-3'}>
                <CheckmarkSvg></CheckmarkSvg>
              </i>
            )}
          </div>
        </div>
      </div>
    </PopupWindow>
  );
};
