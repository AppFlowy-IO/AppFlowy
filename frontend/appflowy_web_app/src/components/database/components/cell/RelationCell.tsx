import {
  FieldId,
  YDatabaseField,
  YDatabaseFields,
  YDatabaseRow,
  YDoc,
  YjsDatabaseKey,
  YjsEditorKey,
} from '@/application/collab.type';
import { useFieldSelector, parseRelationTypeOption } from '@/application/database-yjs';
import { useId } from '@/components/_shared/context-provider/IdProvider';
import { AFConfigContext } from '@/components/app/AppConfig';
import { parseYDatabaseCellToCell } from '@/components/database/components/cell/cell.parse';
import { RelationCell, RelationCellData } from '@/components/database/components/cell/cell.type';
import React, { useContext, useEffect, useMemo, useState } from 'react';
import * as Y from 'yjs';

export default function ({ cell, fieldId }: { cell?: RelationCell; fieldId: string; rowId: string }) {
  const { field } = useFieldSelector(fieldId);
  const workspaceId = useId()?.workspaceId;
  const rowIds = useMemo(() => (cell?.data.toJSON() as RelationCellData) ?? [], [cell?.data]);
  const databaseId = rowIds.length > 0 && field ? parseRelationTypeOption(field).database_id : undefined;
  const databaseService = useContext(AFConfigContext)?.service?.databaseService;
  const [databasePrimaryFieldId, setDatabasePrimaryFieldId] = useState<string | undefined>(undefined);
  const [rows, setRows] = useState<Y.Map<YDoc> | null>();

  useEffect(() => {
    if (!workspaceId || !databaseId) return;
    void databaseService?.getDatabase(workspaceId, databaseId).then(({ databaseDoc: doc, rows }) => {
      const fields = doc
        .getMap(YjsEditorKey.data_section)
        .get(YjsEditorKey.database)
        .get(YjsDatabaseKey.fields) as YDatabaseFields;

      fields.forEach((field, fieldId) => {
        if ((field as YDatabaseField).get(YjsDatabaseKey.is_primary)) {
          setDatabasePrimaryFieldId(fieldId);
        }
      });

      setRows(rows);
    });
  }, [workspaceId, databaseId, databaseService]);

  return (
    <div className={'flex items-center gap-2'}>
      {rowIds.map((rowId) => {
        const rowDoc = rows?.get(rowId);

        return (
          <div key={rowId} className={'cursor-pointer underline'}>
            {rowDoc && databasePrimaryFieldId && (
              <RelationPrimaryValue rowDoc={rowDoc} fieldId={databasePrimaryFieldId} />
            )}
          </div>
        );
      })}
    </div>
  );
}

function RelationPrimaryValue({ rowDoc, fieldId }: { rowDoc: YDoc; fieldId: FieldId }) {
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
