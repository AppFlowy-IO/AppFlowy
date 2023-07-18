import { FieldTypeIcon } from '$app/components/_shared/EditRow/FieldTypeIcon';
import { DropDownShowSvg } from '$app/components/_shared/svg/DropDownShowSvg';
import { FieldType, SelectOptionPB } from '@/services/backend';
import { getBgColor } from '$app/components/_shared/getColor';
import { TrashSvg } from '$app/components/_shared/svg/TrashSvg';
import { IPopupItem, PopupSelect } from '$app/components/_shared/PopupSelect';
import {
  IDatabaseFilter,
  ISelectOption,
  ISelectOptionType,
  SupportedOperatorsByType,
  TDatabaseOperators,
} from '$app_reducers/database/slice';
import { PopupWindow } from '$app/components/_shared/PopupWindow';
import { CellOption } from '$app/components/_shared/EditRow/Options/CellOption';
import { useAppSelector } from '$app/stores/store';
import { MouseEventHandler, useEffect, useMemo, useRef, useState } from 'react';
import { EditorCheckSvg } from '$app/components/_shared/svg/EditorCheckSvg';
import { EditorUncheckSvg } from '$app/components/_shared/svg/EditorUncheckSvg';

export const DatabaseFilterItem = ({
  data,
  onSave,
  onDelete,
  index,
}: {
  data: IDatabaseFilter | null;
  onSave: (filter: IDatabaseFilter) => void;
  onDelete?: () => void;
  index: number;
}) => {
  // stores
  const columns = useAppSelector((state) => state.database.columns);
  const fields = useAppSelector((state) => state.database.fields);
  const filtersStore = useAppSelector((state) => state.database.filters);

  // values
  const [currentLogicalOperator, setCurrentLogicalOperator] = useState<'and' | 'or'>('and');
  const [currentFieldId, setCurrentFieldId] = useState<string | null>(data?.fieldId ?? null);
  const [currentOperator, setCurrentOperator] = useState<TDatabaseOperators | null>(data?.operator ?? null);
  const [currentValue, setCurrentValue] = useState<SelectOptionPB[] | string | boolean | null>(data?.value ?? null);

  useEffect(() => {
    if (data) {
      setCurrentLogicalOperator(data.logicalOperator);
      setCurrentFieldId(data.fieldId);
      setCurrentOperator(data.operator);
      setCurrentValue(data.value);
    } else {
      setCurrentLogicalOperator('and');
      setCurrentFieldId(null);
      setCurrentOperator(null);
      setCurrentValue(null);
    }
  }, [data]);

  // ui
  const [showLogicalOperatorSelect, setShowLogicalOperatorSelect] = useState(false);
  const refLogicalOperatorSelect = useRef<HTMLDivElement>(null);
  const [logicalOperatorSelectTop, setLogicalOperatorSelectTop] = useState(0);
  const [logicalOperatorSelectLeft, setLogicalOperatorSelectLeft] = useState(0);

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

  useEffect(() => {
    // if the user is typing in a text input, don't update the filter
    if (textInputActive) return;

    if (currentFieldId && currentFieldType !== undefined && currentOperator && currentValue !== null) {
      if (currentFieldType === FieldType.RichText && (currentValue as string).length === 0) {
        return;
      }

      onSave({
        logicalOperator: currentLogicalOperator,
        fieldId: currentFieldId,
        fieldType: currentFieldType,
        operator: currentOperator,
        value: currentValue,
      });
    }
  }, [currentFieldId, currentFieldType, currentOperator, currentValue, textInputActive]);

  // 1. not all field types support filtering
  // 2. we don't want to show fields that are already in use
  const supportedColumns = useMemo(
    () =>
      columns
        .filter((column) => SupportedOperatorsByType[fields[column.fieldId].fieldType] !== undefined)
        .filter((column) => filtersStore.findIndex((filter) => filter?.fieldId === column.fieldId) === -1),
    [columns, fields, filtersStore]
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

  const onValueOptionsClick: MouseEventHandler = () => {
    if (!refValueOptions.current) return;
    const { left, top, width, height } = refValueOptions.current.getBoundingClientRect();

    setValueOptionsTop(top + height + 5);
    setValueOptionsLeft(left);
    setValueOptionsMinWidth(width);
    setShowValueOptions(true);
  };

  const onLogicalOperatorClick: MouseEventHandler = () => {
    if (!refLogicalOperatorSelect.current) return;
    const { left, top, height } = refLogicalOperatorSelect.current.getBoundingClientRect();

    setLogicalOperatorSelectTop(top + height + 5);
    setLogicalOperatorSelectLeft(left);
    setShowLogicalOperatorSelect(true);
  };

  const onSelectFieldClick = (id: string) => {
    setCurrentFieldId(id);
    setShowFieldSelect(false);

    switch (fields[id].fieldType) {
      case FieldType.RichText:
        setCurrentValue('');
        setCurrentOperator(null);
        break;
      case FieldType.MultiSelect:
      case FieldType.SingleSelect:
        setCurrentValue([]);
        setCurrentOperator(null);
        break;
      case FieldType.Checkbox:
        setCurrentOperator('is');
        setCurrentValue(false);
        break;
      default:
        setCurrentOperator(null);
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

  const onSelectLogicalOperatorClick = (operator: 'and' | 'or') => {
    setCurrentLogicalOperator(operator);
    setShowLogicalOperatorSelect(false);
  };

  const LogicalOperators: ('and' | 'or')[] = ['and', 'or'];

  return (
    <>
      <div className='flex items-center gap-4'>
        <div className={'w-[88px]'}>
          {index === 0 ? (
            <span className={'text-sm text-text-caption'}>Where</span>
          ) : (
            <div
              ref={refLogicalOperatorSelect}
              onClick={onLogicalOperatorClick}
              className={`flex w-[88px] items-center justify-between rounded-lg border px-2 py-1 ${
                showLogicalOperatorSelect ? 'border-fill-hover' : 'border-line-border'
              }`}
            >
              and
              <i
                className={`h-5 w-5 transition-transform duration-500 ${
                  showLogicalOperatorSelect ? 'rotate-180' : 'rotate-0'
                }`}
              >
                <DropDownShowSvg></DropDownShowSvg>
              </i>
            </div>
          )}
        </div>

        <div
          ref={refFieldSelect}
          onClick={onFieldClick}
          className={`flex w-[180px] items-center justify-between rounded-lg border px-2 py-1 ${
            showFieldSelect ? 'border-fill-hover' : 'border-line-border'
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
            <span className={'text-text-placeholder'}>Select a field</span>
          )}
          <i className={`h-5 w-5 transition-transform duration-500 ${showFieldSelect ? 'rotate-180' : 'rotate-0'}`}>
            <DropDownShowSvg></DropDownShowSvg>
          </i>
        </div>

        <div
          ref={refOperatorSelect}
          onClick={onOperatorClick}
          className={`flex w-[180px] items-center justify-between rounded-lg border px-2 py-1 ${
            showOperatorSelect ? 'border-fill-hover' : 'border-line-border'
          }`}
        >
          {currentOperator ? (
            <span>{currentOperator}</span>
          ) : (
            <span className={'text-text-placeholder'}>Select an option</span>
          )}
          <i className={`h-5 w-5 transition-transform duration-500 ${showOperatorSelect ? 'rotate-180' : 'rotate-0'}`}>
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
                  showValueOptions ? 'border-fill-hover' : 'border-line-border'
                }`}
              >
                {currentValue ? (
                  <div className={'flex flex-1 items-center gap-1 overflow-hidden'}>
                    {(currentValue as SelectOptionPB[]).length === 0 && (
                      <span className={'text-text-placeholder'}>none selected</span>
                    )}
                    {(currentValue as SelectOptionPB[]).map((option, i) => (
                      <span className={`${getBgColor(option.color)} rounded px-2 py-0.5 text-xs`} key={i}>
                        {option.name}
                      </span>
                    ))}
                  </div>
                ) : (
                  <span className={'text-text-placeholder'}>Select an option</span>
                )}

                <i className={'h-5 w-5 transition-transform duration-200'}>
                  <DropDownShowSvg></DropDownShowSvg>
                </i>
              </div>
            )}
            {currentFieldType === FieldType.RichText && (
              <div
                className={`flex w-[180px] items-center justify-between rounded-lg border px-2 py-1 ${
                  textInputActive ? 'border-fill-hover' : 'border-line-border'
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
            {currentFieldType === FieldType.Checkbox && (
              <div
                onClick={() => setCurrentValue(!currentValue)}
                className={`flex w-[180px] cursor-pointer items-center gap-2 rounded-lg border border-line-border px-2 py-1`}
              >
                <button className={'h-5 w-5'}>
                  {currentValue ? <EditorCheckSvg></EditorCheckSvg> : <EditorUncheckSvg></EditorUncheckSvg>}
                </button>
                <span>{currentValue ? 'Checked' : 'Unchecked'}</span>
              </div>
            )}
          </>
        ) : (
          <div className={`flex w-[180px] items-center justify-between rounded-lg border border-line-border px-2 py-1`}>
            <span className={'text-text-placeholder'}>Select field</span>
          </div>
        )}

        <button
          onClick={() => onDelete?.()}
          className={`rounded p-1 hover:bg-fill-list-hover ${data ? 'opacity-100' : 'opacity-0'}`}
        >
          <i className={'block h-[16px] w-[16px]'}>
            <TrashSvg />
          </i>
        </button>
      </div>

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

      {showLogicalOperatorSelect && (
        <PopupSelect
          items={LogicalOperators.map<IPopupItem>((operatorName) => ({
            icon: null,
            title: operatorName,
            onClick: () => onSelectLogicalOperatorClick(operatorName),
          }))}
          className={'fixed z-10 text-sm'}
          style={{ top: `${logicalOperatorSelectTop}px`, left: `${logicalOperatorSelectLeft}px`, width: `${88}px` }}
          onOutsideClick={() => setShowLogicalOperatorSelect(false)}
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
          <div className={'font-medium text-text-caption'}>Value option</div>
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
    </>
  );
};
