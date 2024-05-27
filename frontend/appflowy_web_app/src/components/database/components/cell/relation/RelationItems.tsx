import { YDatabaseField, YDatabaseFields, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/collab.type';
import { parseRelationTypeOption, useFieldSelector } from '@/application/database-yjs';
import { useId } from '@/components/_shared/context-provider/IdProvider';
import { AFConfigContext } from '@/components/app/AppConfig';
import { RelationCell, RelationCellData } from '@/components/database/components/cell/cell.type';
import { RelationPrimaryValue } from '@/components/database/components/cell/relation/RelationPrimaryValue';
import React, { useContext, useEffect, useMemo, useState } from 'react';
import * as Y from 'yjs';

function RelationItems({ style, cell, fieldId }: { cell: RelationCell; fieldId: string; style?: React.CSSProperties }) {
  const { field } = useFieldSelector(fieldId);
  const workspaceId = useId()?.workspaceId;
  const rowIds = useMemo(() => (cell.data.toJSON() as RelationCellData) ?? [], [cell.data]);
  const databaseId = rowIds.length > 0 && field ? parseRelationTypeOption(field).database_id : undefined;
  const databaseService = useContext(AFConfigContext)?.service?.databaseService;
  const [databasePrimaryFieldId, setDatabasePrimaryFieldId] = useState<string | undefined>(undefined);
  const [rows, setRows] = useState<Y.Map<YDoc> | null>();

  useEffect(() => {
    if (!workspaceId || !databaseId) return;
    void databaseService?.getDatabase(workspaceId, databaseId, rowIds).then(({ databaseDoc: doc, rows }) => {
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
  }, [workspaceId, databaseId, databaseService, rowIds]);

  return (
    <div style={style} className={'relation-cell flex w-full items-center gap-2'}>
      {rowIds.map((rowId) => {
        const rowDoc = rows?.get(rowId);

        return (
          <div key={rowId} className={'w-full cursor-pointer underline'}>
            {rowDoc && databasePrimaryFieldId && (
              <RelationPrimaryValue rowDoc={rowDoc} fieldId={databasePrimaryFieldId} />
            )}
          </div>
        );
      })}
    </div>
  );
}

export default RelationItems;
