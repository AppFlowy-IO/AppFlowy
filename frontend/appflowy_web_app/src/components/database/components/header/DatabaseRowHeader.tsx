import { useCellSelector, usePrimaryFieldId, useRowMetaSelector } from '@/application/database-yjs';
import Title from '@/components/database/components/header/Title';
import React from 'react';

function DatabaseRowHeader({ rowId }: { rowId: string }) {
  const fieldId = usePrimaryFieldId() || '';
  const meta = useRowMetaSelector(rowId);
  const cell = useCellSelector({
    rowId,
    fieldId,
  });

  return <Title icon={meta?.icon} name={cell?.data as string} />;
}

export default DatabaseRowHeader;
