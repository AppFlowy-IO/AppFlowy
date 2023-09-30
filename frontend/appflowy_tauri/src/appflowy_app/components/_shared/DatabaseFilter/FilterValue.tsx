import { FieldType } from '@/services/backend';
import { getBgColor } from '$app/components/_shared/getColor';
import { DropDownShowSvg } from '$app/components/_shared/svg/DropDownShowSvg';
import { EditorCheckSvg } from '$app/components/_shared/svg/EditorCheckSvg';
import { EditorUncheckSvg } from '$app/components/_shared/svg/EditorUncheckSvg';
import React, { useRef, useState } from 'react';
import { DatabaseFieldMap, ISelectOption, ISelectOptionType } from '$app_reducers/database/slice';
import { CellOption } from '$app/components/_shared/EditRow/Options/CellOption';
import { Popover } from '@mui/material';

interface IFilterValueProps {
  currentFieldId: string | null;
  currentFieldType: FieldType | undefined;
  currentValue: string[] | string | boolean | null;
  fields: DatabaseFieldMap;
  textInputActive: boolean;
  setTextInputActive: (v: boolean) => void;
  setCurrentValue: (v: string[] | string | boolean | null) => void;
  onValueOptionClick: (option: ISelectOption) => void;
}

const WIDTH = 180;

export const FilterValue = ({
  currentFieldId,
  currentFieldType,
  currentValue,
  fields,
  textInputActive,
  setTextInputActive,
  setCurrentValue,
  onValueOptionClick,
}: IFilterValueProps) => {
  const [showValueOptions, setShowValueOptions] = useState(false);

  const refValueOptions = useRef<HTMLDivElement>(null);

  const getSelectOption = (optionId: string) => {
    if (!currentFieldId) return undefined;
    return (fields[currentFieldId].fieldOptions as ISelectOptionType).selectOptions.find(
      (option) => option.selectOptionId === optionId
    );
  };

  return currentFieldId ? (
    <>
      {(currentFieldType === FieldType.MultiSelect || currentFieldType === FieldType.SingleSelect) && (
        <>
          <div
            ref={refValueOptions}
            onClick={() => setShowValueOptions(true)}
            className={`flex items-center justify-between rounded-lg border px-2 py-1 ${
              showValueOptions ? 'border-fill-hover' : 'border-line-border'
            }`}
            style={{ width: `${WIDTH}px` }}
          >
            {currentValue ? (
              <div className={'flex flex-1 items-center gap-1 overflow-hidden'}>
                {(currentValue as string[]).length === 0 && (
                  <span className={'text-text-placeholder'}>none selected</span>
                )}
                {(currentValue as string[]).map((option, i) => (
                  <span className={`${getBgColor(getSelectOption(option)?.color)} rounded px-2 py-0.5 text-xs`} key={i}>
                    {getSelectOption(option)?.title}
                  </span>
                ))}
              </div>
            ) : (
              <span className={'text-text-placeholder'}>Select an option</span>
            )}

            <i className={`h-5 w-5 transition-transform duration-500 ${showValueOptions ? 'rotate-180' : 'rotate-0'}`}>
              <DropDownShowSvg></DropDownShowSvg>
            </i>
          </div>

          <Popover
            open={showValueOptions}
            anchorOrigin={{
              vertical: 'bottom',
              horizontal: 'left',
            }}
            transformOrigin={{
              vertical: 'top',
              horizontal: 'left',
            }}
            anchorEl={refValueOptions.current}
            onClose={() => setShowValueOptions(false)}
          >
            <div style={{ width: `${WIDTH}px` }} className={'flex flex-col gap-2 p-2 text-xs'}>
              <div className={'font-medium text-text-caption'}>Value option</div>
              <div className={'flex flex-col gap-1'}>
                {(fields[currentFieldId].fieldOptions as ISelectOptionType).selectOptions.map((option, index) => (
                  <CellOption
                    key={index}
                    option={option}
                    checked={(currentValue as string[]).findIndex((o) => o === option.selectOptionId) !== -1}
                    noSelect={true}
                    noDetail={true}
                    onOptionClick={() => onValueOptionClick(option)}
                  ></CellOption>
                ))}
              </div>
            </div>
          </Popover>
        </>
      )}
      {currentFieldType === FieldType.RichText && (
        <div
          className={`flex items-center justify-between rounded-lg border px-2 py-1 ${
            textInputActive ? 'border-fill-hover' : 'border-line-border'
          }`}
          style={{ width: `${WIDTH}px` }}
        >
          <input
            placeholder={'Enter value'}
            className={'flex-1'}
            onFocus={() => setTextInputActive(true)}
            onBlur={() => setTextInputActive(false)}
            value={currentValue as string}
            onChange={(e) => setCurrentValue(e.target.value)}
          />
        </div>
      )}
      {currentFieldType === FieldType.Checkbox && (
        <div
          onClick={() => setCurrentValue(!currentValue)}
          className={`flex cursor-pointer items-center gap-2 rounded-lg border border-line-border px-2 py-1`}
          style={{ width: `${WIDTH}px` }}
        >
          <button className={'h-5 w-5'}>
            {currentValue ? <EditorCheckSvg></EditorCheckSvg> : <EditorUncheckSvg></EditorUncheckSvg>}
          </button>
          <span>{currentValue ? 'Checked' : 'Unchecked'}</span>
        </div>
      )}
    </>
  ) : (
    <div
      className={`flex items-center justify-between rounded-lg border border-line-border px-2 py-1`}
      style={{ width: `${WIDTH}px` }}
    >
      <span className={'text-text-placeholder'}>Select field</span>
    </div>
  );
};
