import { useFieldsSelector, useNavigateToRow, usePrimaryFieldId } from '@/application/database-yjs';
import EventPaperTitle from '@/components/database/components/calendar/event/EventPaperTitle';
import { Property } from '@/components/database/components/property';
import { Tooltip } from '@mui/material';
import React from 'react';
import { ReactComponent as ExpandMoreIcon } from '$icons/16x/full_view.svg';
import { useTranslation } from 'react-i18next';

function EventPaper({ rowId }: { rowId: string }) {
  const primaryFieldId = usePrimaryFieldId();

  const fields = useFieldsSelector().filter((column) => column.fieldId !== primaryFieldId);

  const navigateToRow = useNavigateToRow();
  const { t } = useTranslation();

  return (
    <div className={'max-h-[260px] w-[360px] overflow-y-auto'}>
      <div className={'flex h-fit w-full flex-col items-center justify-center py-2 px-3'}>
        <div className={'flex w-full items-center justify-end'}>
          <Tooltip placement={'bottom'} title={t('tooltip.openAsPage')}>
            <button
              color={'primary'}
              className={'rounded bg-bg-body p-1 hover:bg-fill-list-hover'}
              onClick={() => {
                navigateToRow?.(rowId);
              }}
            >
              <ExpandMoreIcon />
            </button>
          </Tooltip>
        </div>
        <div className={'event-properties flex w-full flex-1 flex-col gap-4 overflow-y-auto py-2'}>
          {primaryFieldId && <EventPaperTitle rowId={rowId} fieldId={primaryFieldId} />}
          {fields.map((field) => {
            return <Property fieldId={field.fieldId} rowId={rowId} key={field.fieldId} />;
          })}
        </div>
      </div>
    </div>
  );
}

export default EventPaper;
