import React from 'react';
import { CreatedTimeField, LastEditedTimeField, TimeStampCell } from '$app/components/database/application';

interface Props {
  field: LastEditedTimeField | CreatedTimeField;
  cell: TimeStampCell;
}

function TimestampCell({ cell }: Props) {
  return <div className={'flex h-full w-full items-center p-2 text-xs font-medium'}>{cell.data.dataTime}</div>;
}

export default TimestampCell;
