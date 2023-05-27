import { KeyboardEventHandler, useEffect, useRef, useState } from 'react';
import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { useCell } from '$app/components/_shared/database-hooks/useCell';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { SelectOptionCellDataPB, SelectOptionPB } from '@/services/backend';
import { useTranslation } from 'react-i18next';
import { SelectOptionCellBackendService } from '$app/stores/effects/database/cell/select_option_bd_svc';
import { useAppSelector } from '$app/stores/store';
import { ISelectOptionType } from '$app_reducers/database/slice';
import { PopupWindow } from '$app/components/_shared/PopupWindow';
import { CellOption } from '$app/components/_shared/EditRow/Options/CellOption';
import { SelectedOption } from '$app/components/_shared/EditRow/Options/SelectedOption';

export const CellOptionsPopup = ({
  top,
  left,
  cellIdentifier,
  cellCache,
  fieldController,
  onOutsideClick,
  openOptionDetail,
}: {
  top: number;
  left: number;
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
  onOutsideClick: () => void;
  openOptionDetail: (_left: number, _top: number, _select_option: SelectOptionPB) => void;
}) => {
  const inputRef = useRef<HTMLInputElement>(null);
  const { t } = useTranslation();
  const [value, setValue] = useState('');
  const { data } = useCell(cellIdentifier, cellCache, fieldController);
  const databaseStore = useAppSelector((state) => state.database);

  useEffect(() => {
    if (inputRef?.current) {
      inputRef.current.focus();
    }
  }, [inputRef]);

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

  return (
    <PopupWindow className={'p-2 text-xs'} onOutsideClick={onOutsideClick} left={left} top={top}>
      <div onKeyDown={onKeyDownWrapper} className={'flex flex-col gap-2 p-2'}>
        <div className={'border-shades-3 flex flex-1 items-center gap-2 rounded border bg-main-selector px-2 '}>
          <div className={'flex flex-wrap items-center gap-2 text-black'}>
            {(data as SelectOptionCellDataPB)?.select_options?.map((option, index) => (
              <SelectedOption
                option={option}
                key={index}
                cellIdentifier={cellIdentifier}
                clearValue={() => setValue('')}
              ></SelectedOption>
            ))}
          </div>
          <input
            ref={inputRef}
            className={'py-2'}
            value={value}
            onChange={(e) => setValue(e.target.value)}
            placeholder={t('grid.selectOption.searchOption') ?? ''}
            onKeyDown={onKeyDown}
          />
          <div className={'font-mono text-shade-3'}>{value.length}/30</div>
        </div>
        <div className={'-mx-4 h-[1px] bg-shade-6'}></div>
        <div className={'font-medium text-shade-3'}>{t('grid.selectOption.panelTitle') ?? ''}</div>
        <div className={'flex flex-col gap-1'}>
          {(databaseStore.fields[cellIdentifier.fieldId]?.fieldOptions as ISelectOptionType).selectOptions.map(
            (option, index) => (
              <CellOption
                key={index}
                option={option}
                checked={
                  !!(data as SelectOptionCellDataPB)?.select_options?.find(
                    (selectedOption) => selectedOption.id === option.selectOptionId
                  )
                }
                cellIdentifier={cellIdentifier}
                openOptionDetail={openOptionDetail}
                clearValue={() => setValue('')}
              ></CellOption>
            )
          )}
        </div>
      </div>
    </PopupWindow>
  );
};
