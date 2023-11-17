import React, { useEffect, useRef } from 'react';
import RecordTitle from '$app/components/database/components/edit_record/RecordTitle';
import RecordProperties from '$app/components/database/components/edit_record/record_properties/RecordProperties';
import { Divider } from '@mui/material';
import { TextCell } from '$app/components/database/application';
import { Page } from '$app_reducers/pages/slice';

interface Props {
  page: Page | null;
  cell: TextCell;
  icon?: string;
}
function RecordHeader({ page, cell, icon }: Props) {
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
    <div ref={ref} className={'pb-4'}>
      <RecordTitle page={page} cell={cell} icon={icon} />
      <RecordProperties documentId={page?.id} cell={cell} />
      <Divider />
    </div>
  );
}

export default RecordHeader;
