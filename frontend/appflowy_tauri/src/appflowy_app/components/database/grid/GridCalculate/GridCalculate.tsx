import React from 'react';
import { useDatabaseVisibilityRows } from '$app/components/database';
import { Field } from '$app/components/database/application';
import { DEFAULT_FIELD_WIDTH } from '$app/components/database/grid/GridRow';

interface Props {
  field: Field;
  index: number;
}

function GridCalculate({ field, index }: Props) {
  const rowMetas = useDatabaseVisibilityRows();
  const count = rowMetas.length;
  const width = field.width ?? DEFAULT_FIELD_WIDTH;

  return (
    <div
      style={{
        width,
        visibility: index === 0 ? 'visible' : 'hidden',
      }}
      className={'flex justify-end'}
    >
      <span className={'mr-2 text-text-caption'}>Count</span>
      <span>{count}</span>
    </div>
  );
}

export default GridCalculate;
