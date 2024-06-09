import { FieldId, YDatabaseRow, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/collab.type';
import { parseYDatabaseCellToCell } from '@/application/database-yjs/cell.parse';
import React, { useEffect, useState } from 'react';

export function RelationPrimaryValue({ rowDoc, fieldId }: { rowDoc: YDoc; fieldId: FieldId }) {
  const [text, setText] = useState<string | null>(null);
  const [row, setRow] = useState<YDatabaseRow | null>(null);

  useEffect(() => {
    const data = rowDoc.getMap(YjsEditorKey.data_section);

    const onRowChange = () => {
      setRow(data?.get(YjsEditorKey.database_row) as YDatabaseRow);
    };

    onRowChange();
    data?.observe(onRowChange);
    return () => {
      data?.unobserve(onRowChange);
    };
  }, [rowDoc]);

  useEffect(() => {
    if (!row) return;
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
  }, [row, fieldId]);

  return <div>{text}</div>;
}
