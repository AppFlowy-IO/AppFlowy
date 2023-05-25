import { SelectOptionColorPB, SelectOptionPB } from '@/services/backend';
import { getBgColor } from '$app/components/_shared/getColor';
import { CheckmarkSvg } from '$app/components/_shared/svg/CheckmarkSvg';
import { Details2Svg } from '$app/components/_shared/svg/Details2Svg';
import { ISelectOption } from '$app_reducers/database/slice';
import { SelectOptionCellBackendService } from '$app/stores/effects/database/cell/select_option_bd_svc';
import { MouseEventHandler } from 'react';
import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';

export const CellOption = ({
  option,
  checked,
  cellIdentifier,
  openOptionDetail,
  clearValue,
}: {
  option: ISelectOption;
  checked: boolean;
  cellIdentifier: CellIdentifier;
  openOptionDetail: (_left: number, _top: number, _select_option: SelectOptionPB) => void;
  clearValue: () => void;
}) => {
  const onOptionDetailClick: MouseEventHandler = (e) => {
    e.stopPropagation();
    let target = e.target as HTMLElement;

    while (!(target instanceof HTMLButtonElement)) {
      if (target.parentElement === null) return;
      target = target.parentElement;
    }

    const selectOption = new SelectOptionPB({
      id: option.selectOptionId,
      name: option.title,
      color: option.color ?? SelectOptionColorPB.Purple,
    });

    const { right: _left, top: _top } = target.getBoundingClientRect();
    openOptionDetail(_left, _top, selectOption);
  };

  const onToggleOptionClick: MouseEventHandler = async () => {
    if (checked) {
      await new SelectOptionCellBackendService(cellIdentifier).unselectOption([option.selectOptionId]);
    } else {
      await new SelectOptionCellBackendService(cellIdentifier).selectOption([option.selectOptionId]);
    }
    clearValue();
  };

  return (
    <div
      onClick={onToggleOptionClick}
      className={'flex cursor-pointer items-center justify-between rounded-lg px-2 py-1.5 hover:bg-main-secondary'}
    >
      <div className={`${getBgColor(option.color)} rounded px-2 py-0.5`}>{option.title}</div>
      <div className={'flex items-center'}>
        {checked && (
          <button className={'h-5 w-5 p-1'}>
            <CheckmarkSvg></CheckmarkSvg>
          </button>
        )}
        <button onClick={onOptionDetailClick} className={'h-6 w-6 p-1'}>
          <Details2Svg></Details2Svg>
        </button>
      </div>
    </div>
  );
};
