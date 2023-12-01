import React from 'react';
import { UndeterminedDateField } from '$app/components/database/application';
import DateTimeFormat from '$app/components/database/components/field_types/date/DateTimeFormat';
import { Divider } from '@mui/material';

function DateTimeFieldActions({ field }: { field: UndeterminedDateField }) {
  return (
    <>
      <div className={'px-1'}>
        <DateTimeFormat field={field} />
      </div>
      <Divider className={'my-2'} />
    </>
  );
}

export default DateTimeFieldActions;
