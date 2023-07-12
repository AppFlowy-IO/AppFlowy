import { t } from 'i18next';
import AddSvg from '../../_shared/svg/AddSvg';
import { FieldTypeIcon } from '../EditRow/FieldTypeIcon';
import { useAppSelector } from '$app/stores/store';
import { IPopupItem, PopupSelect } from '$app/components/_shared/PopupSelect';
import { FieldType, SelectOptionPB } from '@/services/backend';
import { MouseEventHandler, useMemo, useRef, useState } from 'react';
import useOutsideClick from '$app/components/_shared/useOutsideClick';
import { DropDownShowSvg } from '$app/components/_shared/svg/DropDownShowSvg';
import {
  ISelectOption,
  ISelectOptionType,
  SupportedOperatorsByType,
  TDatabaseOperators,
} from '$app_reducers/database/slice';
import { CellOption } from '$app/components/_shared/EditRow/Options/CellOption';
import { PopupWindow } from '$app/components/_shared/PopupWindow';
import { getBgColor } from '$app/components/_shared/getColor';
import { TrashSvg } from '$app/components/_shared/svg/TrashSvg';

export const DatabaseFilterPopup = ({ onOutsideClick }: { onOutsideClick: () => void }) => {
  const refContainer = useRef<HTMLDivElement>(null);

  useOutsideClick(refContainer, onOutsideClick);

  // stores
  const columns = useAppSelector((state) => state.database.columns);
  const fields = useAppSelector((state) => state.database.fields);
  const filters = useAppSelector((state) => state.database.filters);

  // values
  const [currentFieldId, setCurrentFieldId] = useState<string | null>(null);
  const [currentOperator, setCurrentOperator] = useState<TDatabaseOperators | null>(null);
  const [currentValue, setCurrentValue] = useState<SelectOptionPB[] | string | boolean | null>(null);

  // ui
  const [showFieldSelect, setShowFieldSelect] = useState(false);
  const refFieldSelect = useRef<HTMLDivElement>(null);
  const [fieldSelectTop, setFieldSelectTop] = useState(0);
  const [fieldSelectLeft, setFieldSelectLeft] = useState(0);

  const [showOperatorSelect, setShowOperatorSelect] = useState(false);
  const refOperatorSelect = useRef<HTMLDivElement>(null);
  const [operatorSelectTop, setOperatorSelectTop] = useState(0);
  const [operatorSelectLeft, setOperatorSelectLeft] = useState(0);

  const [showValueOptions, setShowValueOptions] = useState(false);
  const refValueOptions = useRef<HTMLDivElement>(null);
  const [valueOptionsTop, setValueOptionsTop] = useState(0);
  const [valueOptionsLeft, setValueOptionsLeft] = useState(0);
  const [valueOptionsMinWidth, setValueOptionsMinWidth] = useState(0);

  const [textInputActive, setTextInputActive] = useState(false);

  // shortcut
  const currentFieldType = useMemo(
    () => (currentFieldId ? fields[currentFieldId].fieldType : undefined),
    [currentFieldId, fields]
  );

  // not all field types support filtering
  const supportedColumns = useMemo(
    () => columns.filter((column) => SupportedOperatorsByType[fields[column.fieldId].fieldType] !== undefined),
    [columns, fields]
  );

  const onFieldClick: MouseEventHandler = (e) => {
    if (!refFieldSelect.current) return;
    const { left, top, height } = refFieldSelect.current.getBoundingClientRect();

    setFieldSelectTop(top + height + 5);
    setFieldSelectLeft(left);
    setShowFieldSelect(true);
  };

  const onOperatorClick: MouseEventHandler = (e) => {
    if (!refOperatorSelect.current) return;
    const { left, top, height } = refOperatorSelect.current.getBoundingClientRect();

    setOperatorSelectTop(top + height + 5);
    setOperatorSelectLeft(left);
    setShowOperatorSelect(true);
  };

  const onValueOptionsClick: MouseEventHandler = (e) => {
    if (!refValueOptions.current) return;
    const { left, top, width, height } = refValueOptions.current.getBoundingClientRect();

    setValueOptionsTop(top + height + 5);
    setValueOptionsLeft(left);
    setValueOptionsMinWidth(width);
    setShowValueOptions(true);
  };

  const onSelectFieldClick = (id: string) => {
    setCurrentFieldId(id);
    setShowFieldSelect(false);

    switch (fields[id].fieldType) {
      case FieldType.RichText:
        setCurrentValue('');
        console.log('text selected');
        break;
      case FieldType.MultiSelect:
      case FieldType.SingleSelect:
        setCurrentValue([]);
        break;
      case FieldType.Checkbox:
        setCurrentValue(false);
        break;
      default:
        setCurrentValue(null);
    }
  };

  const onSelectOperatorClick = (operator: TDatabaseOperators) => {
    setCurrentOperator(operator);
    setShowOperatorSelect(false);
  };

  const onValueOptionClick = (option: ISelectOption) => {
    const value = currentValue as SelectOptionPB[];

    if (value.findIndex((v) => v.id === option.selectOptionId) === -1) {
      setCurrentValue([
        ...value,
        new SelectOptionPB({ id: option.selectOptionId, name: option.title, color: option.color }),
      ]);
    } else {
      setCurrentValue(value.filter((v) => v.id !== option.selectOptionId));
    }
  };

  return (
    <>
      <div className={'fixed inset-0 z-10 backdrop-blur-sm'}></div>

      <div className={'fixed inset-0 z-10 flex items-center justify-center overflow-y-auto'}>
        <div className='flex flex-col rounded-lg bg-white shadow-md' ref={refContainer}>
          <div className='px-6 pt-6 text-sm text-shade-3'>{t('grid.settings.filter')}</div>

          <div className='overflow-y-scroll text-sm'>
            {/* null row represents new filter */}
            {filters.concat([null]).map((filter, index: number) => (
              <div className='flex items-center gap-4 px-6 py-6' key={index}>
                <div className={'w-[88px]'}>
                  {index === 0 ? (
                    <span className={'text-sm text-shade-3'}>Where</span>
                  ) : (
                    <div className='rounded-lg border border-gray-300'>and</div>
                  )}
                </div>

                <div
                  ref={refFieldSelect}
                  onClick={onFieldClick}
                  className={`flex w-[180px] items-center justify-between rounded-lg border px-2 py-1 ${
                    showFieldSelect ? 'border-main-accent' : 'border-shade-4'
                  }`}
                >
                  {currentFieldType !== undefined && currentFieldId ? (
                    <div className={'flex items-center gap-2'}>
                      <i className={'block h-5 w-5'}>
                        <FieldTypeIcon fieldType={currentFieldType}></FieldTypeIcon>
                      </i>
                      <span>{fields[currentFieldId].title}</span>
                    </div>
                  ) : (
                    <span className={'text-shade-4'}>Select a field</span>
                  )}
                  <i
                    className={`h-5 w-5 transition-transform duration-500 ${
                      showFieldSelect ? 'rotate-180' : 'rotate-0'
                    }`}
                  >
                    <DropDownShowSvg></DropDownShowSvg>
                  </i>
                </div>

                <div
                  ref={refOperatorSelect}
                  onClick={onOperatorClick}
                  className={`flex w-[180px] items-center justify-between rounded-lg border px-2 py-1 ${
                    showOperatorSelect ? 'border-main-accent' : 'border-shade-4'
                  }`}
                >
                  {currentOperator ? (
                    <span>{currentOperator}</span>
                  ) : (
                    <span className={'text-shade-4'}>Select an option</span>
                  )}
                  <i
                    className={`h-5 w-5 transition-transform duration-500 ${
                      showOperatorSelect ? 'rotate-180' : 'rotate-0'
                    }`}
                  >
                    <DropDownShowSvg></DropDownShowSvg>
                  </i>
                </div>

                {currentFieldId ? (
                  <>
                    {(currentFieldType === FieldType.MultiSelect || currentFieldType === FieldType.SingleSelect) && (
                      <div
                        ref={refValueOptions}
                        onClick={onValueOptionsClick}
                        className={`flex w-[180px] items-center justify-between rounded-lg border px-2 py-1 ${
                          showValueOptions ? 'border-main-accent' : 'border-shade-4'
                        }`}
                      >
                        {currentValue ? (
                          <div className={'flex flex-1 items-center gap-1 overflow-hidden'}>
                            {(currentValue as SelectOptionPB[]).length === 0 && (
                              <span className={'text-shade-4'}>none selected</span>
                            )}
                            {(currentValue as SelectOptionPB[]).map((option, i) => (
                              <span className={`${getBgColor(option.color)} rounded px-2 py-0.5 text-xs`} key={i}>
                                {option.name}
                              </span>
                            ))}
                          </div>
                        ) : (
                          <span className={'text-shade-4'}>Select an option</span>
                        )}

                        <i className={'h-5 w-5 transition-transform duration-200'}>
                          <DropDownShowSvg></DropDownShowSvg>
                        </i>
                      </div>
                    )}
                    {currentFieldType === FieldType.RichText && (
                      <div
                        className={`flex w-[180px] items-center justify-between rounded-lg border px-2 py-1 ${
                          textInputActive ? 'border-main-accent' : 'border-shade-4'
                        }`}
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
                  </>
                ) : (
                  <div className={`flex w-[180px] items-center justify-between rounded-lg border px-2 py-1`}>
                    <span className={'text-shade-4'}>Select field</span>
                  </div>
                )}

                <div className=''>
                  <button className={'rounded p-1 hover:bg-main-secondary'}>
                    <i className={'block h-[16px] w-[16px]'}>
                      <TrashSvg />
                    </i>
                  </button>
                </div>
              </div>
            ))}
          </div>

          <hr />

          <button className='flex cursor-pointer items-center gap-2 px-6 py-6 text-sm text-shade-1'>
            <div className='h-5 w-5'>
              <AddSvg />
            </div>
            {t('grid.settings.addFilter')}
          </button>

          {showFieldSelect && (
            <PopupSelect
              items={supportedColumns.map<IPopupItem>((c) => ({
                icon: (
                  <i className={'block h-5 w-5'}>
                    <FieldTypeIcon fieldType={fields[c.fieldId].fieldType}></FieldTypeIcon>
                  </i>
                ),
                title: fields[c.fieldId].title,
                onClick: () => onSelectFieldClick(c.fieldId),
              }))}
              className={'fixed z-10 text-sm'}
              style={{ top: `${fieldSelectTop}px`, left: `${fieldSelectLeft}px`, width: `${180}px` }}
              onOutsideClick={() => setShowFieldSelect(false)}
            ></PopupSelect>
          )}
          {showOperatorSelect && (
            <PopupSelect
              items={SupportedOperatorsByType[currentFieldType ? currentFieldType : FieldType.RichText].map<IPopupItem>(
                (operatorName) => ({
                  icon: null,
                  title: operatorName,
                  onClick: () => onSelectOperatorClick(operatorName),
                })
              )}
              className={'fixed z-10 text-sm'}
              style={{ top: `${operatorSelectTop}px`, left: `${operatorSelectLeft}px`, width: `${180}px` }}
              onOutsideClick={() => setShowOperatorSelect(false)}
            ></PopupSelect>
          )}
          {showValueOptions && currentFieldId && (
            <PopupWindow
              left={valueOptionsLeft}
              top={valueOptionsTop}
              className={'flex flex-col gap-2 p-2 text-xs'}
              onOutsideClick={() => setShowValueOptions(false)}
              style={{ minWidth: `${valueOptionsMinWidth}px` }}
            >
              <div className={'font-medium text-shade-3'}>Value option</div>
              <div className={'flex flex-col gap-1'}>
                {(fields[currentFieldId].fieldOptions as ISelectOptionType).selectOptions.map((option, index) => (
                  <CellOption
                    key={index}
                    option={option}
                    checked={(currentValue as SelectOptionPB[]).findIndex((o) => o.id === option.selectOptionId) !== -1}
                    noSelect={true}
                    noDetail={true}
                    onOptionClick={() => onValueOptionClick(option)}
                  ></CellOption>
                ))}
              </div>
            </PopupWindow>
          )}
        </div>
      </div>
    </>
  );
};
