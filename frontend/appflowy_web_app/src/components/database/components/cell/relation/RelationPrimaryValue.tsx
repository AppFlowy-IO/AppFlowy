import { FieldId, YDatabaseRow, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/collab.type';
import { parseYDatabaseCellToCell } from '@/components/database/components/cell/cell.parse';
import React, { useEffect, useState } from 'react';

export function RelationPrimaryValue({ rowDoc, fieldId }: { rowDoc: YDoc; fieldId: FieldId }) {
  const [text, setText] = useState<string | null>(null);

  useEffect(() => {
    const row = rowDoc.getMap(YjsEditorKey.data_section).get(YjsEditorKey.database_row) as YDatabaseRow;
    const cells = row.get(YjsDatabaseKey.cells);
    const primaryCell = cells.get(fieldId);

    if (!primaryCell) return;
    const observeHandler = () => {
      setText(parseYDatabaseCellToCell(primaryCell).data as string);
    };

    observeHandler();

    primaryCell.observe(observeHandler);
    return () => {
      primaryCell.unobserve(observeHandler);
    };
  }, [rowDoc, fieldId]);

  return <div>{text}</div>;
}
