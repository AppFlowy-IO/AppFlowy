import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { SelectOptionCellDataPB, SelectOptionColorPB, SelectOptionPB } from '@/services/backend';
import { PopupWindow } from '$app/components/_shared/PopupWindow';
import { ISelectOption, ISelectOptionType } from '$app_reducers/database/slice';
import { Details2Svg } from '$app/components/_shared/svg/Details2Svg';
import { useAppSelector } from '$app/stores/store';
import { useCell } from '$app/components/_shared/database-hooks/useCell';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { EditorCheckSvg } from '$app/components/_shared/svg/EditorCheckSvg';
import { EditorUncheckSvg } from '$app/components/_shared/svg/EditorUncheckSvg';
import AddSvg from '$app/components/_shared/svg/AddSvg';
import { useTranslation } from 'react-i18next';
import { SelectOptionCellBackendService } from '$app/stores/effects/database/cell/select_option_bd_svc';
import { useEffect, useState } from 'react';
import { CheckListProgress } from '$app/components/_shared/CheckListProgress';

export const CheckListPopup = ({
  left,
  top,
  cellIdentifier,
  cellCache,
  fieldController,
  openCheckListDetail,
  onOutsideClick,
}: {
  left: number;
  top: number;
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
  openCheckListDetail: (left: number, top: number, option: SelectOptionPB) => void;
  onOutsideClick: () => void;
}) => {
  const databaseStore = useAppSelector((state) => state.database);
  const { data } = useCell(cellIdentifier, cellCache, fieldController);
  const { t } = useTranslation('');

  const [allOptionsCount, setAllOptionsCount] = useState(0);
  const [selectedOptionsCount, setSelectedOptionsCount] = useState(0);
  const [newOptions, setNewOptions] = useState<string[]>([]);

  useEffect(() => {
    setAllOptionsCount(
      (databaseStore.fields[cellIdentifier.fieldId]?.fieldOptions as ISelectOptionType)?.selectOptions?.length || 0
    );
  }, [databaseStore, cellIdentifier]);

  useEffect(() => {
    setSelectedOptionsCount((data as SelectOptionCellDataPB)?.select_options?.length || 0);
  }, [data]);

  const onToggleOptionClick = async (option: SelectOptionPB) => {
    if ((data as SelectOptionCellDataPB)?.select_options?.find((selectedOption) => selectedOption.id === option.id)) {
      await new SelectOptionCellBackendService(cellIdentifier).unselectOption([option.id]);
    } else {
      await new SelectOptionCellBackendService(cellIdentifier).selectOption([option.id]);
    }
  };

  const onCheckListDetailClick = (e: any, option: ISelectOption) => {
    e.stopPropagation();
    let target = e.target as HTMLElement;

    while (!(target instanceof HTMLButtonElement)) {
      if (target.parentElement === null) return;
      target = target.parentElement;
    }

    const selectOption = new SelectOptionPB({
      id: option.selectOptionId,
      name: option.title,
      color: option.color || SelectOptionColorPB.Purple,
    });

    const { right: _left, top: _top } = target.getBoundingClientRect();
    openCheckListDetail(_left, _top, selectOption);
  };

  const newOptionClick = () => {
    setNewOptions([...newOptions, '']);
  };

  const updateNewOption = (index: number, value: string) => {
    const newOptionsCopy = [...newOptions];
    newOptionsCopy[index] = value;
    setNewOptions(newOptionsCopy);
  };

  const onNewOptionKeyDown = (index: number, e: KeyboardEvent) => {
    if (e.key === 'Enter') {
      void onSaveNewOptionClick(index);
    }
  };

  const onSaveNewOptionClick = async (index: number) => {
    await new SelectOptionCellBackendService(cellIdentifier).createOption({ name: newOptions[index] });
    setNewOptions(newOptions.filter((_, i) => i !== index));
  };

  return (
    <PopupWindow className={'text-xs'} onOutsideClick={onOutsideClick} left={left} top={top}>
      <div className={'min-w-[320px]'}>
        <div className={'px-4 pt-8 pb-4'}>
          <CheckListProgress completed={selectedOptionsCount} max={allOptionsCount} />
        </div>

        <div className={'flex flex-col p-2'}>
          {(databaseStore.fields[cellIdentifier.fieldId]?.fieldOptions as ISelectOptionType).selectOptions.map(
            (option, index) => (
              <div
                key={index}
                className={
                  'flex cursor-pointer items-center justify-between rounded-lg px-2 py-1.5 hover:bg-main-secondary'
                }
                onClick={() =>
                  onToggleOptionClick(
                    new SelectOptionPB({
                      id: option.selectOptionId,
                      name: option.title,
                      color: option.color || SelectOptionColorPB.Purple,
                    })
                  )
                }
              >
                <div className={'h-5 w-5'}>
                  {(data as SelectOptionCellDataPB)?.select_options?.find((so) => so.id === option.selectOptionId) ? (
                    <EditorCheckSvg></EditorCheckSvg>
                  ) : (
                    <EditorUncheckSvg></EditorUncheckSvg>
                  )}
                </div>
                <div className={`flex-1 px-2 py-0.5`}>{option.title}</div>
                <div className={'flex items-center'}>
                  <button onClick={(e) => onCheckListDetailClick(e, option)} className={'h-6 w-6 p-1'}>
                    <Details2Svg></Details2Svg>
                  </button>
                </div>
              </div>
            )
          )}
          {newOptions.map((option, index) => (
            <div
              key={index}
              className={'flex cursor-pointer items-center justify-between rounded-lg px-2 py-1.5 hover:bg-shade-6'}
            >
              <input
                onKeyDown={(e) => onNewOptionKeyDown(index, e as unknown as KeyboardEvent)}
                className={'min-w-0 flex-1 pl-7'}
                value={option}
                onChange={(e) => updateNewOption(index, e.target.value)}
              />
              <button
                onClick={() => onSaveNewOptionClick(index)}
                className={
                  'flex items-center gap-2 rounded-lg bg-main-accent px-4 py-2 text-white hover:bg-main-hovered'
                }
              >
                {t('grid.selectOption.create')}
              </button>
            </div>
          ))}
        </div>
        <div className={'h-[1px] bg-shade-6'}></div>
        <div className={'p-2'}>
          <button
            onClick={() => newOptionClick()}
            className={'flex w-full items-center gap-2 rounded-lg px-2 py-2 hover:bg-shade-6'}
          >
            <i className={'h-5 w-5'}>
              <AddSvg></AddSvg>
            </i>
            <span>{t('grid.field.addOption')}</span>
          </button>
        </div>
      </div>
    </PopupWindow>
  );
};
