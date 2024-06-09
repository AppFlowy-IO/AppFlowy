import React from 'react';
import { useDatabaseVisibilityRows } from '$app/components/database';
import { Field } from '$app/application/database';
import { DEFAULT_FIELD_WIDTH, GRID_ACTIONS_WIDTH } from '$app/components/database/grid/constants';
import { useTranslation } from 'react-i18next';

interface Props {
  field: Field;
  index: number;
  getContainerRef?: () => React.RefObject<HTMLDivElement>;
}

export function GridCalculate({ field, index }: Props) {
  const rowMetas = useDatabaseVisibilityRows();
  const count = rowMetas.length;
  const width = index === 0 ? GRID_ACTIONS_WIDTH : field.width ?? DEFAULT_FIELD_WIDTH;
  const { t } = useTranslation();

  return (
    <div
      style={{
        width,
      }}
      className={'flex justify-end py-2 text-text-title'}
    >
      {field.isPrimary ? (
        <>
          <span className={'mr-2 text-text-caption'}>{t('grid.calculationTypeLabel.count')}</span>
          <span>{count}</span>
        </>
      ) : null}
    </div>
  );
}

export default GridCalculate;
