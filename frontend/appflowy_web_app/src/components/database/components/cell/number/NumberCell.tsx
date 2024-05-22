import { currencyFormaterMap, NumberFormat, useFieldSelector, parseNumberTypeOptions } from '@/application/database-yjs';
import { CellProps, NumberCell as NumberCellType } from '@/components/database/components/cell/cell.type';
import React, { useMemo } from 'react';
import Decimal from 'decimal.js';

export function NumberCell({ cell, fieldId, style }: CellProps<NumberCellType>) {
  const { field } = useFieldSelector(fieldId);

  const format = useMemo(() => (field ? parseNumberTypeOptions(field).format : NumberFormat.Num), [field]);

  const className = useMemo(() => {
    const classList = ['select-text', 'cursor-text'];

    return classList.join(' ');
  }, []);

  const value = useMemo(() => {
    if (!cell) return '';
    const numberFormater = currencyFormaterMap[format];

    if (!numberFormater) return cell.data;
    return numberFormater(new Decimal(cell.data).toNumber());
  }, [cell, format]);

  if (value === undefined) return null;
  return (
    <div style={style} className={className}>
      {value}
    </div>
  );
}
