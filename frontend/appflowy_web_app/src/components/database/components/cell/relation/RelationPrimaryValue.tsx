import { FieldId, YDatabaseCell, YDatabaseRow, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/types';
import { FieldType } from '@/application/database-yjs';
import { parseYDatabaseCellToCell } from '@/application/database-yjs/cell.parse';
import React, { useEffect, useState } from 'react';

export function RelationPrimaryValue({ rowDoc, fieldId }: { rowDoc: YDoc; fieldId?: FieldId }) {
  const [text, setText] = useState<string | null>(null);
  const [row, setRow] = useState<YDatabaseRow | null>(null);

  useEffect(() => {
    const data = rowDoc.getMap(YjsEditorKey.data_section);

    const onRowChange = () => {
      setRow(data?.get(YjsEditorKey.database_row) as YDatabaseRow);
    };

    onRowChange();
    data?.observeDeep(onRowChange);
    return () => {
      data?.unobserveDeep(onRowChange);
    };
  }, [rowDoc]);

  useEffect(() => {
    if (!row) return;
    const cells = row.get(YjsDatabaseKey.cells);

    let primaryCell: YDatabaseCell | undefined;

    if (fieldId) {
      primaryCell = cells?.get(fieldId);
    } else {
      const fieldId = Array.from(cells.keys()).find((key) => {
        const fieldType = cells.get(key)?.get(YjsDatabaseKey.field_type);

        if (!fieldType) return false;
        return Number(fieldType) === FieldType.RichText;
      });

      if (fieldId) {
        primaryCell = cells?.get(fieldId);
      }
    }

    const observeHandler = () => {
      if (!primaryCell) return;
      setText(parseYDatabaseCellToCell(primaryCell).data as string);
    };

    observeHandler();

    primaryCell?.observe(observeHandler);
    return () => {
      primaryCell?.unobserve(observeHandler);
    };
  }, [row, fieldId]);

  return <div>{text}</div>;
}
