import { KeyboardEventHandler, useEffect, useRef, useState } from 'react';
import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { useCell } from '$app/components/_shared/database-hooks/useCell';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { SelectOptionCellDataPB, SelectOptionColorPB, SelectOptionPB } from '@/services/backend';
import { getBgColor } from '$app/components/_shared/getColor';
import { useTranslation } from 'react-i18next';
import { Details2Svg } from '$app/components/_shared/svg/Details2Svg';
import { CheckmarkSvg } from '$app/components/_shared/svg/CheckmarkSvg';
import { CloseSvg } from '$app/components/_shared/svg/CloseSvg';
import useOutsideClick from '$app/components/_shared/useOutsideClick';
import { SelectOptionCellBackendService } from '$app/stores/effects/database/cell/select_option_bd_svc';
import { useAppSelector } from '$app/stores/store';
import { ISelectOptionType } from '$app/stores/reducers/database/slice';

export const CellOptionsPopup = ({
  top,
  left,
  cellIdentifier,
  cellCache,
  fieldController,
  onOutsideClick,
}: {
  top: number;
  left: number;
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
  onOutsideClick: () => void;
}) => {
  const ref = useRef<HTMLDivElement>(null);
  const { t } = useTranslation('');
  const [adjustedTop, setAdjustedTop] = useState(-100);
  const [value, setValue] = useState('');
  const { data, cellController } = useCell(cellIdentifier, cellCache, fieldController);
  const databaseStore = useAppSelector((state) => state.database);

  useEffect(() => {
    if (!ref.current) return;
    const { height } = ref.current.getBoundingClientRect();
    if (top + height + 40 > window.innerHeight) {
      setAdjustedTop(window.innerHeight - height - 40);
    } else {
      setAdjustedTop(top);
    }
  }, [ref, window, top, left]);

  useOutsideClick(ref, async () => {
    onOutsideClick();
  });

  const onKeyDown: KeyboardEventHandler = async (e) => {
    if (e.key === 'Enter' && value.length > 0) {
      await new SelectOptionCellBackendService(cellIdentifier).createOption({ name: value });
      setValue('');
    }
  };

  const onUnselectOptionClick = async (option: SelectOptionPB) => {
    await new SelectOptionCellBackendService(cellIdentifier).unselectOption([option.id]);
    setValue('');
  };

  const onToggleOptionClick = async (option: SelectOptionPB) => {
    if (
      (data as SelectOptionCellDataPB | undefined)?.select_options?.find(
        (selectedOption) => selectedOption.id === option.id
      )
    ) {
      await new SelectOptionCellBackendService(cellIdentifier).unselectOption([option.id]);
    } else {
      await new SelectOptionCellBackendService(cellIdentifier).selectOption([option.id]);
    }
    setValue('');
  };

  useEffect(() => {
    console.log('loaded data: ', data);
    console.log('have stored ', databaseStore.fields[cellIdentifier.fieldId]);
  }, [data]);

  return (
    <div
      ref={ref}
      className={`fixed z-10 rounded-lg bg-white px-2 py-2 text-xs shadow-md transition-opacity duration-300 ${
        adjustedTop === -100 ? 'opacity-0' : 'opacity-100'
      }`}
      style={{ top: `${adjustedTop + 40}px`, left: `${left}px` }}
    >
      <div className={'flex flex-col gap-2 p-2'}>
        <div className={'border-shades-3 flex flex-1 items-center gap-2 rounded border bg-main-selector px-2 '}>
          <div className={'flex flex-wrap items-center gap-2 text-black'}>
            {(data as SelectOptionCellDataPB | undefined)?.select_options?.map((option, index) => (
              <div className={`${getBgColor(option.color)} flex items-center gap-0.5 rounded px-1 py-0.5`} key={index}>
                <span>{option?.name || ''}</span>
                <button onClick={() => onUnselectOptionClick(option)} className={'h-5 w-5 cursor-pointer'}>
                  <CloseSvg></CloseSvg>{' '}
                </button>
              </div>
            )) || ''}
          </div>
          <input
            className={'py-2'}
            value={value}
            onChange={(e) => setValue(e.target.value)}
            placeholder={t('grid.selectOption.searchOption') || ''}
            onKeyDown={onKeyDown}
          />
          <div className={'font-mono text-shade-3'}>{value.length}/30</div>
        </div>
        <div className={'-mx-4 h-[1px] bg-shade-6'}></div>
        <div className={'font-semibold text-shade-3'}>{t('grid.selectOption.panelTitle') || ''}</div>
        <div className={'flex flex-col gap-1'}>
          {(databaseStore.fields[cellIdentifier.fieldId]?.fieldOptions as ISelectOptionType).selectOptions.map(
            (option, index) => (
              <div
                key={index}
                onClick={() =>
                  onToggleOptionClick(
                    new SelectOptionPB({
                      id: option.selectOptionId,
                      name: option.title,
                      color: option.color || SelectOptionColorPB.Purple,
                    })
                  )
                }
                className={
                  'flex cursor-pointer items-center justify-between rounded-lg px-2 py-1.5 hover:bg-main-secondary'
                }
              >
                <div className={`${getBgColor(option.color)} rounded px-2 py-0.5`}>{option.title}</div>
                <div className={'flex items-center'}>
                  {(data as SelectOptionCellDataPB | undefined)?.select_options?.find(
                    (selectedOption) => selectedOption.id === option.selectOptionId
                  ) && (
                    <button className={'h-5 w-5 p-1'}>
                      <CheckmarkSvg></CheckmarkSvg>
                    </button>
                  )}
                  <button className={'h-6 w-6 p-1'}>
                    <Details2Svg></Details2Svg>
                  </button>
                </div>
              </div>
            )
          )}
        </div>
      </div>
    </div>
  );
};
