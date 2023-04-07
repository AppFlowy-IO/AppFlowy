import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { KeyboardEventHandler, useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { SelectOptionCellDataPB, SelectOptionColorPB } from '@/services/backend';
import { getBgColor } from '$app/components/_shared/getColor';
import { CloseSvg } from '$app/components/_shared/svg/CloseSvg';
import { SelectOptionCellBackendService } from '$app/stores/effects/database/cell/select_option_bd_svc';
import useOutsideClick from '$app/components/_shared/useOutsideClick';
import { TrashSvg } from '$app/components/_shared/svg/TrashSvg';
import { CheckmarkSvg } from '$app/components/_shared/svg/CheckmarkSvg';

export const EditCellOptionPopup = ({
  left,
  top,
  cellIdentifier,
  cellCache,
  fieldController,
  onOutsideClick,
}: {
  left: number;
  top: number;
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
  onOutsideClick: () => void;
}) => {
  const ref = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const { t } = useTranslation('');
  const [adjustedTop, setAdjustedTop] = useState(-100);
  const [value, setValue] = useState('');

  useOutsideClick(ref, async () => {
    onOutsideClick();
  });

  useEffect(() => {
    if (!ref.current) return;
    const { height } = ref.current.getBoundingClientRect();
    if (top + height > window.innerHeight) {
      setAdjustedTop(window.innerHeight - height);
    } else {
      setAdjustedTop(top);
    }
  }, [ref, window, top, left]);

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

  const onDeleteOptionClick = () => {
    console.log('delete option');
  };

  return (
    <div
      ref={ref}
      onKeyDown={onKeyDownWrapper}
      className={`fixed z-10 rounded-lg bg-white px-2 py-2 text-xs shadow-md transition-opacity duration-300 ${
        adjustedTop === -100 ? 'opacity-0' : 'opacity-100'
      }`}
      style={{ top: `${adjustedTop}px`, left: `${left}px` }}
    >
      <div className={'flex flex-col gap-2 p-2'}>
        <div className={'border-shades-3 flex flex-1 items-center gap-2 rounded border bg-main-selector px-2 '}>
          <input
            ref={inputRef}
            className={'py-2'}
            value={value}
            onChange={(e) => setValue(e.target.value)}
            onKeyDown={onKeyDown}
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
          <div className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-main-secondary'}>
            <div className={'flex items-center gap-2'}>
              <div className={`h-4 w-4 rounded-full ${getBgColor(SelectOptionColorPB.Purple)}`}></div>
              <span>{t('grid.selectOption.purpleColor')}</span>
            </div>
            <i className={'block h-3 w-3'}>
              <CheckmarkSvg></CheckmarkSvg>
            </i>
          </div>
          <div className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-main-secondary'}>
            <div className={'flex items-center gap-2'}>
              <div className={`h-4 w-4 rounded-full ${getBgColor(SelectOptionColorPB.Pink)}`}></div>
              <span>{t('grid.selectOption.pinkColor')}</span>
            </div>
            <i className={'block h-3 w-3'}>
              <CheckmarkSvg></CheckmarkSvg>
            </i>
          </div>
          <div className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-main-secondary'}>
            <div className={'flex items-center gap-2'}>
              <div className={`h-4 w-4 rounded-full ${getBgColor(SelectOptionColorPB.LightPink)}`}></div>
              <span>{t('grid.selectOption.lightPinkColor')}</span>
            </div>
            <i className={'block h-3 w-3'}>
              <CheckmarkSvg></CheckmarkSvg>
            </i>
          </div>
          <div className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-main-secondary'}>
            <div className={'flex items-center gap-2'}>
              <div className={`h-4 w-4 rounded-full ${getBgColor(SelectOptionColorPB.Orange)}`}></div>
              <span>{t('grid.selectOption.orangeColor')}</span>
            </div>
            <i className={'block h-3 w-3'}>
              <CheckmarkSvg></CheckmarkSvg>
            </i>
          </div>
          <div className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-main-secondary'}>
            <div className={'flex items-center gap-2'}>
              <div className={`h-4 w-4 rounded-full ${getBgColor(SelectOptionColorPB.Yellow)}`}></div>
              <span>{t('grid.selectOption.yellowColor')}</span>
            </div>
            <i className={'block h-3 w-3'}>
              <CheckmarkSvg></CheckmarkSvg>
            </i>
          </div>
          <div className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-main-secondary'}>
            <div className={'flex items-center gap-2'}>
              <div className={`h-4 w-4 rounded-full ${getBgColor(SelectOptionColorPB.Lime)}`}></div>
              <span>{t('grid.selectOption.limeColor')}</span>
            </div>
            <i className={'block h-3 w-3'}>
              <CheckmarkSvg></CheckmarkSvg>
            </i>
          </div>
          <div className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-main-secondary'}>
            <div className={'flex items-center gap-2'}>
              <div className={`h-4 w-4 rounded-full ${getBgColor(SelectOptionColorPB.Green)}`}></div>
              <span>{t('grid.selectOption.greenColor')}</span>
            </div>
            <i className={'block h-3 w-3'}>
              <CheckmarkSvg></CheckmarkSvg>
            </i>
          </div>
          <div className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-main-secondary'}>
            <div className={'flex items-center gap-2'}>
              <div className={`h-4 w-4 rounded-full ${getBgColor(SelectOptionColorPB.Aqua)}`}></div>
              <span>{t('grid.selectOption.aquaColor')}</span>
            </div>
            <i className={'block h-3 w-3'}>
              <CheckmarkSvg></CheckmarkSvg>
            </i>
          </div>
          <div className={'flex cursor-pointer items-center justify-between rounded-lg p-2 hover:bg-main-secondary'}>
            <div className={'flex items-center gap-2'}>
              <div className={`h-4 w-4 rounded-full ${getBgColor(SelectOptionColorPB.Blue)}`}></div>
              <span>{t('grid.selectOption.blueColor')}</span>
            </div>
            <i className={'block h-3 w-3'}>
              <CheckmarkSvg></CheckmarkSvg>
            </i>
          </div>
        </div>
      </div>
    </div>
  );
};
