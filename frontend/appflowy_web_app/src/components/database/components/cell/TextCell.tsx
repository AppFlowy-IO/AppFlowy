import { FieldId } from '@/application/collab.type';
import { useReadOnly } from '@/application/database-yjs';
import { TextCell } from '@/components/database/components/cell/cell.type';
import React from 'react';

function TextCellComponent({ cell }: { cell?: TextCell; rowId: string; fieldId: FieldId }) {
  const readOnly = useReadOnly();

  return <div className={`cursor-text ${readOnly ? 'select-text' : ''}`}>{cell?.data}</div>;
}

export default TextCellComponent;
