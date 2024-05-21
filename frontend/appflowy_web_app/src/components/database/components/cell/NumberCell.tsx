import { FieldId } from '@/application/collab.type';
import { currencyFormaterMap, NumberFormat, useFieldSelector, parseNumberTypeOptions } from '@/application/database-yjs';
import { UrlCell } from '@/components/database/components/cell/cell.type';
import React, { useMemo } from 'react';
import Decimal from 'decimal.js';

export default function ({ cell, fieldId }: { cell?: UrlCell; rowId: string; fieldId: FieldId }) {
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

  return <div className={className}>{value}</div>;
}
