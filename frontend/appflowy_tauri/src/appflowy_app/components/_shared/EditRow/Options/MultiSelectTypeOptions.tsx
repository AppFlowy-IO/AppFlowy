import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { ISelectOptionType } from '$app_reducers/database/slice';
import { CellOption } from '$app/components/_shared/EditRow/Options/CellOption';
import { SelectOptionPB } from '@/services/backend';
import { useAppSelector } from '$app/stores/store';
import { KeyboardEventHandler, useEffect, useRef, useState } from 'react';
import { SelectOptionCellBackendService } from '$app/stores/effects/database/cell/select_option_bd_svc';

export const MultiSelectTypeOptions = ({
  cellIdentifier,
  openOptionDetail,
}: {
  cellIdentifier: CellIdentifier;
  openOptionDetail?: (_left: number, _top: number, _select_option: SelectOptionPB) => void;
}) => {
  const inputRef = useRef<HTMLInputElement>(null);
  const inputContainerRef = useRef<HTMLDivElement>(null);
  const fieldsStore = useAppSelector((state) => state.database.fields);
  const [value, setValue] = useState('');
  const [showInput, setShowInput] = useState(false);
  const [newInputWidth, setNewInputWidth] = useState(0);

  const onKeyDown: KeyboardEventHandler = async (e) => {
    if (e.key === 'Enter' && value.length > 0) {
      await new SelectOptionCellBackendService(cellIdentifier).createOption({ name: value, isSelect: false });
      setValue('');
    }

    if (e.key === 'Escape') {
      setShowInput(false);
    }
  };

  useEffect(() => {
    if (inputRef?.current && showInput) {
      inputRef.current.focus();
    }
  }, [inputRef, showInput, newInputWidth]);

  useEffect(() => {
    if (inputContainerRef?.current && showInput) {
      setNewInputWidth(inputContainerRef.current.getBoundingClientRect().width - 56);
    } else {
      setNewInputWidth(0);
    }
  }, [inputContainerRef, showInput]);

  return (
    <div className={'flex flex-col'}>
      <hr className={'-mx-2 my-2 border-line-divider'} />
      <div className={'flex flex-col gap-1'}>
        <div className={'flex items-center justify-between px-3 py-1.5'}>
          <div>Options</div>
          {!showInput && <button onClick={() => setShowInput(true)}>Add option</button>}
        </div>
        {showInput && (
          <div
            ref={inputContainerRef}
            className={`border-shades-3 bg-main-selector flex items-center gap-2 rounded border px-2`}
          >
            {newInputWidth > 0 && (
              <input
                ref={inputRef}
                style={{ width: newInputWidth }}
                className={'py-2'}
                value={value}
                onChange={(e) => setValue(e.target.value)}
                onBlur={() => setShowInput(false)}
                onKeyDown={onKeyDown}
              />
            )}
            <div className={'font-mono text-text-caption'}>{value.length}/30</div>
          </div>
        )}

        {(fieldsStore[cellIdentifier.fieldId]?.fieldOptions as ISelectOptionType).selectOptions.map((option, index) => (
          <CellOption
            key={index}
            option={option}
            noSelect={true}
            checked={false}
            cellIdentifier={cellIdentifier}
            openOptionDetail={openOptionDetail}
            clearValue={() => setValue('')}
          ></CellOption>
        ))}
      </div>
    </div>
  );
};
