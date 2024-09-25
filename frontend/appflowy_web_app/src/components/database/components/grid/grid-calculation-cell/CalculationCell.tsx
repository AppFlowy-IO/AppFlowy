import { YjsDatabaseKey } from '@/application/types';
import { currencyFormaterMap, FieldType, parseNumberTypeOptions, useFieldSelector } from '@/application/database-yjs';
import { CalculationType } from '@/application/database-yjs/database.type';
import Decimal from 'decimal.js';
import { isNaN } from 'lodash-es';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

export interface ICalculationCell {
  value: string;
  fieldId: string;
  id: string;
  type: CalculationType;
}

export interface CalculationCellProps {
  cell?: ICalculationCell;
}

export function CalculationCell({ cell }: CalculationCellProps) {
  const { t } = useTranslation();

  const fieldId = cell?.fieldId || '';
  const { field } = useFieldSelector(fieldId);
  const format = useMemo(
    () =>
      field && Number(field?.get(YjsDatabaseKey.type)) === FieldType.Number
        ? parseNumberTypeOptions(field).format
        : undefined,
    [field]
  );

  const prefix = useMemo(() => {
    if (!cell) return '';

    switch (cell.type) {
      case CalculationType.Average:
        return t('grid.calculationTypeLabel.average');
      case CalculationType.Max:
        return t('grid.calculationTypeLabel.max');
      case CalculationType.Count:
        return t('grid.calculationTypeLabel.count');
      case CalculationType.Min:
        return t('grid.calculationTypeLabel.min');
      case CalculationType.Sum:
        return t('grid.calculationTypeLabel.sum');
      case CalculationType.CountEmpty:
        return t('grid.calculationTypeLabel.countEmptyShort');
      case CalculationType.CountNonEmpty:
        return t('grid.calculationTypeLabel.countNonEmptyShort');
      default:
        return '';
    }
  }, [cell, t]);

  const num = useMemo(() => {
    const value = cell?.value;

    if (value === undefined || isNaN(value)) return '';

    if (format && currencyFormaterMap[format]) {
      return currencyFormaterMap[format](new Decimal(value).toNumber());
    }

    return parseFloat(value);
  }, [cell?.value, format]);

  return (
    <div className={'h-full w-full px-1 text-right uppercase leading-[36px] text-text-caption'}>
      <span className={'text-xs'}>{prefix}</span>
      <span className={'ml-2 text-sm font-medium text-text-title'}>{num}</span>
    </div>
  );
}

export default CalculationCell;
