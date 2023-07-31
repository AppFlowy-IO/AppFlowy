import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { SelectOptionCellDataPB, SelectOptionPB } from '@/services/backend';
import { PopupWindow } from '$app/components/_shared/PopupWindow';
import { ISelectOptionType } from '$app_reducers/database/slice';
import { useAppSelector } from '$app/stores/store';
import { useCell } from '$app/components/_shared/database-hooks/useCell';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { SelectOptionCellBackendService } from '$app/stores/effects/database/cell/select_option_bd_svc';
import { useEffect, useState } from 'react';
import { CheckListProgress } from '$app/components/_shared/CheckListProgress';
import { NewCheckListOption } from '$app/components/_shared/EditRow/CheckList/NewCheckListOption';
import { CheckListOption } from '$app/components/_shared/EditRow/CheckList/CheckListOption';
import { NewCheckListButton } from '$app/components/_shared/EditRow/CheckList/NewCheckListButton';

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

  const [allOptionsCount, setAllOptionsCount] = useState(0);
  const [selectedOptionsCount, setSelectedOptionsCount] = useState(0);
  const [newOptions, setNewOptions] = useState<string[]>([]);

  useEffect(() => {
    setAllOptionsCount(
      (databaseStore.fields[cellIdentifier.fieldId]?.fieldOptions as ISelectOptionType)?.selectOptions?.length ?? 0
    );
  }, [databaseStore, cellIdentifier]);

  useEffect(() => {
    setSelectedOptionsCount((data as SelectOptionCellDataPB)?.select_options?.length ?? 0);
  }, [data]);

  const onToggleOptionClick = async (option: SelectOptionPB) => {
    if ((data as SelectOptionCellDataPB)?.select_options?.find((selectedOption) => selectedOption.id === option.id)) {
      await new SelectOptionCellBackendService(cellIdentifier).unselectOption([option.id]);
    } else {
      await new SelectOptionCellBackendService(cellIdentifier).selectOption([option.id]);
    }
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
              <CheckListOption
                key={index}
                option={option}
                checked={
                  !!(data as SelectOptionCellDataPB)?.select_options?.find((so) => so.id === option.selectOptionId)
                }
                onToggleOptionClick={onToggleOptionClick}
                openCheckListDetail={openCheckListDetail}
              ></CheckListOption>
            )
          )}
          {newOptions.map((option, index) => (
            <NewCheckListOption
              key={index}
              index={index}
              option={option}
              newOptions={newOptions}
              setNewOptions={setNewOptions}
              cellIdentifier={cellIdentifier}
            ></NewCheckListOption>
          ))}
        </div>
        <div className={'h-[1px] bg-shade-6'}></div>
        <div className={'p-2'}>
          <NewCheckListButton newOptions={newOptions} setNewOptions={setNewOptions}></NewCheckListButton>
        </div>
      </div>
    </PopupWindow>
  );
};
