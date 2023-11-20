import React from 'react';
import { useDatabaseVisibilityFields } from '$app/components/database';
import GridCalculate from '$app/components/database/grid/GridCalculate/GridCalculate';

function GridCalculateRow() {
  const fields = useDatabaseVisibilityFields();

  return (
    <div className='flex grow items-center'>
      {fields.map((field, index) => {
        return <GridCalculate index={index} key={field.id} field={field} />;
      })}
    </div>
  );
}

export default GridCalculateRow;
