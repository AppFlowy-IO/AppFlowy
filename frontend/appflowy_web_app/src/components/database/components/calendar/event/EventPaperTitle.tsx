import { useCellSelector } from '@/application/database-yjs';
import { TextCell } from '@/components/database/components/cell/cell.type';
import { TextProperty } from '@/components/database/components/property/text';
import React from 'react';

function EventPaperTitle({ fieldId, rowId }: { fieldId: string; rowId: string }) {
  const cell = useCellSelector({
    fieldId,
    rowId,
  });

  return <TextProperty cell={cell as TextCell} fieldId={fieldId} rowId={rowId} />;
}

export default EventPaperTitle;
