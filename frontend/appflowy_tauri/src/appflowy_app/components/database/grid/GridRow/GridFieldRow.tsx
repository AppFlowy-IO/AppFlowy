import { useDatabaseVisibilityFields } from '../../Database.hooks';
import { GridField } from '../GridField';
import { DEFAULT_FIELD_WIDTH } from '$app/components/database/grid/GridRow/constants';
import React from 'react';
import NewProperty from '$app/components/database/components/edit_record/record_properties/NewProperty';

export const GridFieldRow = () => {
  const fields = useDatabaseVisibilityFields();

  return (
    <>
      <div className='z-10  flex border-b border-line-divider '>
        <div className={'flex '}>
          {fields.map((field) => {
            return <GridField key={field.id} field={field} />;
          })}
        </div>

        <div className={` w-[${DEFAULT_FIELD_WIDTH}px]`}>
          <NewProperty />
        </div>
      </div>
    </>
  );
};
