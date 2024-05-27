import {
  currencyFormaterMap,
  NumberFormat,
  useFieldSelector,
  parseNumberTypeOptions,
  FieldType,
} from '@/application/database-yjs';
import { CellProps, NumberCell as NumberCellType } from '@/components/database/components/cell/cell.type';
import React, { useMemo } from 'react';
import Decimal from 'decimal.js';

export function NumberCell({ cell, fieldId, style, placeholder }: CellProps<NumberCellType>) {
  const { field } = useFieldSelector(fieldId);

  const format = useMemo(() => (field ? parseNumberTypeOptions(field).format : NumberFormat.Num), [field]);

  const className = useMemo(() => {
    const classList = ['select-text', 'cursor-text'];

    return classList.join(' ');
  }, []);

  const value = useMemo(() => {
    if (!cell || cell.fieldType !== FieldType.Number) return '';
    const numberFormater = currencyFormaterMap[format];

    if (!numberFormater) return cell.data;
    return numberFormater(new Decimal(cell.data).toNumber());
  }, [cell, format]);

  if (value === undefined)
    return placeholder ? (
      <div style={style} className={'text-text-placeholder'}>
        {placeholder}
      </div>
    ) : null;
  return (
    <div style={style} className={className}>
      {value}
    </div>
  );
}
