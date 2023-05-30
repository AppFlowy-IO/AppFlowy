import { SelectOptionPB } from '@/services/backend';
import { EditorCheckSvg } from '$app/components/_shared/svg/EditorCheckSvg';
import { EditorUncheckSvg } from '$app/components/_shared/svg/EditorUncheckSvg';
import { Details2Svg } from '$app/components/_shared/svg/Details2Svg';
import { ISelectOption } from '$app_reducers/database/slice';
import { MouseEventHandler } from 'react';

export const CheckListOption = ({
  option,
  checked,
  onToggleOptionClick,
  openCheckListDetail,
}: {
  option: ISelectOption;
  checked: boolean;
  onToggleOptionClick: (v: SelectOptionPB) => void;
  openCheckListDetail: (left: number, top: number, option: SelectOptionPB) => void;
}) => {
  const onCheckListDetailClick: MouseEventHandler = (e) => {
    e.stopPropagation();
    let target = e.target as HTMLElement;

    while (!(target instanceof HTMLButtonElement)) {
      if (target.parentElement === null) return;
      target = target.parentElement;
    }

    const selectOption = new SelectOptionPB({
      id: option.selectOptionId,
      name: option.title,
    });

    const { right: _left, top: _top } = target.getBoundingClientRect();
    openCheckListDetail(_left, _top, selectOption);
  };

  return (
    <div
      className={'flex cursor-pointer items-center justify-between rounded-lg px-2 py-1.5 hover:bg-main-secondary'}
      onClick={() =>
        onToggleOptionClick(
          new SelectOptionPB({
            id: option.selectOptionId,
            name: option.title,
          })
        )
      }
    >
      <div className={'h-5 w-5'}>
        {checked ? <EditorCheckSvg></EditorCheckSvg> : <EditorUncheckSvg></EditorUncheckSvg>}
      </div>
      <div className={`flex-1 px-2 py-0.5`}>{option.title}</div>
      <div className={'flex items-center'}>
        <button onClick={onCheckListDetailClick} className={'h-6 w-6 p-1'}>
          <Details2Svg></Details2Svg>
        </button>
      </div>
    </div>
  );
};
