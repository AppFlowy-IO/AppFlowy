import { getBgColor } from '$app/components/_shared/getColor';
import { CloseSvg } from '$app/components/_shared/svg/CloseSvg';
import { SelectOptionPB } from '@/services/backend';
import { SelectOptionCellBackendService } from '$app/stores/effects/database/cell/select_option_bd_svc';
import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { MouseEventHandler } from 'react';

export const SelectedOption = ({
  option,
  cellIdentifier,
  clearValue,
}: {
  option: SelectOptionPB;
  cellIdentifier: CellIdentifier;
  clearValue: () => void;
}) => {
  const onUnselectOptionClick: MouseEventHandler = async () => {
    await new SelectOptionCellBackendService(cellIdentifier).unselectOption([option.id]);
    clearValue();
  };

  return (
    <div className={`${getBgColor(option.color)} flex items-center gap-0.5 rounded px-1 py-0.5`}>
      <span>{option?.name ?? ''}</span>
      <button onClick={onUnselectOptionClick} className={'h-5 w-5 cursor-pointer'}>
        <CloseSvg></CloseSvg>
      </button>
    </div>
  );
};
