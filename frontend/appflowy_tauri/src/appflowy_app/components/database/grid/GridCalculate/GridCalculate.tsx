import React from 'react';
import { useDatabaseVisibilityRows } from '$app/components/database';
import { Field } from '$app/components/database/application';
import { DEFAULT_FIELD_WIDTH, GRID_ACTIONS_WIDTH } from '$app/components/database/grid/constants';

interface Props {
  field: Field;
  index: number;
  getContainerRef?: () => React.RefObject<HTMLDivElement>;
}

function GridCalculate({ field, index }: Props) {
  const rowMetas = useDatabaseVisibilityRows();
  const count = rowMetas.length;
  const width = index === 0 ? GRID_ACTIONS_WIDTH : field.width ?? DEFAULT_FIELD_WIDTH;

  return (
    <div
      style={{
        width,
        visibility: index === 1 ? 'visible' : 'hidden',
      }}
      className={'flex justify-end py-2'}
    >
      <span className={'mr-2 text-text-caption'}>Count</span>
      <span>{count}</span>
    </div>
  );
}

export default GridCalculate;
