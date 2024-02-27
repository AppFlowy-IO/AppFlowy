import React, { useEffect, useRef } from 'react';
import RecordTitle from '$app/components/database/components/edit_record/RecordTitle';
import RecordProperties from '$app/components/database/components/edit_record/record_properties/RecordProperties';
import { Divider } from '@mui/material';
import { RowMeta } from '$app/application/database';
import { Page } from '$app_reducers/pages/slice';

interface Props {
  page: Page | null;
  row: RowMeta;
}
function RecordHeader({ page, row }: Props) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;

    if (!el) return;

    const preventSelectionTrigger = (e: MouseEvent) => {
      e.stopPropagation();
    };

    el.addEventListener('mousedown', preventSelectionTrigger);
    return () => {
      el.removeEventListener('mousedown', preventSelectionTrigger);
    };
  }, []);

  return (
    <div ref={ref} className={'px-16 py-4'}>
      <RecordTitle page={page} row={row} />
      <RecordProperties row={row} />
      <Divider />
    </div>
  );
}

export default RecordHeader;
