import { FieldType } from '@/services/backend';
import { TrashSvg } from '$app/components/_shared/svg/TrashSvg';
import {
  IDatabaseFilter,
  ISelectOption,
  SupportedOperatorsByType,
  TDatabaseOperators,
} from '$app_reducers/database/slice';
import { useAppSelector } from '$app/stores/store';
import React, { useEffect, useMemo, useState } from 'react';
import { FieldSelect } from '$app/components/_shared/DatabaseFilter/FieldSelect';
import { LogicalOperatorSelect } from '$app/components/_shared/DatabaseFilter/LogicalOperatorSelect';
import { OperatorSelect } from '$app/components/_shared/DatabaseFilter/OperatorSelect';
import { FilterValue } from '$app/components/_shared/DatabaseFilter/FilterValue';

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
  const [currentValue, setCurrentValue] = useState<string[] | string | boolean | null>(data?.value ?? null);

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
        id: data?.id,
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

  const onSelectFieldClick = (id: string) => {
    setCurrentFieldId(id);

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
  };

  const onValueOptionClick = (option: ISelectOption) => {
    const value = currentValue as string[];

    if (value.findIndex((v) => v === option.selectOptionId) === -1) {
      setCurrentValue([...value, option.selectOptionId]);
    } else {
      setCurrentValue(value.filter((v) => v !== option.selectOptionId));
    }
  };

  return (
    <>
      <div className='flex items-center gap-4'>
        <div className={'w-[88px]'}>
          {index === 0 ? (
            <span className={'text-sm text-text-caption'}>Where</span>
          ) : (
            <LogicalOperatorSelect></LogicalOperatorSelect>
          )}
        </div>

        <FieldSelect
          columns={supportedColumns}
          fields={fields}
          onSelectFieldClick={onSelectFieldClick}
          currentFieldId={currentFieldId}
          currentFieldType={currentFieldType}
        ></FieldSelect>

        <OperatorSelect
          currentOperator={currentOperator}
          currentFieldType={currentFieldType}
          onSelectOperatorClick={onSelectOperatorClick}
        ></OperatorSelect>

        <FilterValue
          currentFieldId={currentFieldId}
          currentFieldType={currentFieldType}
          currentValue={currentValue}
          setCurrentValue={setCurrentValue}
          fields={fields}
          textInputActive={textInputActive}
          setTextInputActive={setTextInputActive}
          onValueOptionClick={onValueOptionClick}
        ></FilterValue>

        <button
          onClick={() => onDelete?.()}
          className={`rounded p-1 hover:bg-fill-list-hover ${data ? 'opacity-100' : 'opacity-0'}`}
        >
          <i className={'block h-[16px] w-[16px]'}>
            <TrashSvg />
          </i>
        </button>
      </div>
    </>
  );
};
