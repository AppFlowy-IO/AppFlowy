import { CalculationType } from '@/application/database-yjs/database.type';
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

  return (
    <div className={'h-full w-full px-1 text-right text-xs font-medium uppercase leading-[36px] text-text-caption'}>
      {prefix}
      <span className={'ml-2 text-text-title'}>{cell?.value ?? ''}</span>
    </div>
  );
}

export default CalculationCell;
