import { useFieldsSelector } from '@/application/database-yjs';
import { Property } from '@/components/database/components/property';
import { IconButton } from '@mui/material';
import React from 'react';
import { ReactComponent as ExpandMoreIcon } from '$icons/16x/full_view.svg';

function EventPaper({ rowId }: { rowId: string }) {
  const fields = useFieldsSelector();

  return (
    <div className={'max-h-[260px] w-[360px] overflow-y-auto'}>
      <div className={'flex h-fit w-full flex-col items-center justify-center py-2 px-3'}>
        <div className={'flex w-full items-center justify-end'}>
          <IconButton size={'small'}>
            <ExpandMoreIcon />
          </IconButton>
        </div>
        <div className={'flex w-full flex-1 flex-col gap-4 overflow-y-auto py-2'}>
          {fields.map((field) => {
            return <Property fieldId={field.fieldId} rowId={rowId} key={field.fieldId} />;
          })}
        </div>
      </div>
    </div>
  );
}

export default EventPaper;
