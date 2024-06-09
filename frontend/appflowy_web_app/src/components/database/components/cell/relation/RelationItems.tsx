import { YDatabaseField, YDatabaseFields, YjsDatabaseKey, YjsEditorKey } from '@/application/collab.type';
import {
  DatabaseContextState,
  parseRelationTypeOption,
  useDatabase,
  useFieldSelector,
  useNavigateToRow,
} from '@/application/database-yjs';
import { RelationCell, RelationCellData } from '@/application/database-yjs/cell.type';
import { RelationPrimaryValue } from '@/components/database/components/cell/relation/RelationPrimaryValue';
import { useGetDatabaseDispatch } from '@/components/database/Database.hooks';
import React, { useEffect, useMemo, useState } from 'react';

function RelationItems({ style, cell, fieldId }: { cell: RelationCell; fieldId: string; style?: React.CSSProperties }) {
  const { field } = useFieldSelector(fieldId);
  const currentDatabaseId = useDatabase()?.get(YjsDatabaseKey.id);
  const { onOpenDatabase, onCloseDatabase } = useGetDatabaseDispatch();
  const rowIds = useMemo(() => {
    return (cell.data?.toJSON() as RelationCellData) ?? [];
  }, [cell.data]);
  const databaseId = rowIds.length > 0 && field ? parseRelationTypeOption(field).database_id : undefined;
  const [databasePrimaryFieldId, setDatabasePrimaryFieldId] = useState<string | undefined>(undefined);
  const [rows, setRows] = useState<DatabaseContextState['rowDocMap'] | null>();

  const navigateToRow = useNavigateToRow();

  useEffect(() => {
    if (!databaseId || !rowIds.length) return;
    void onOpenDatabase({ databaseId, rowIds }).then(({ databaseDoc: doc, rows }) => {
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
  }, [onOpenDatabase, databaseId, rowIds, onCloseDatabase]);

  useEffect(() => {
    return () => {
      if (currentDatabaseId !== databaseId && databaseId) {
        onCloseDatabase(databaseId);
      }
    };
  }, [databaseId, currentDatabaseId, onCloseDatabase]);

  return (
    <div style={style} className={'relation-cell flex w-full items-center gap-2'}>
      {rowIds.map((rowId) => {
        const rowDoc = rows?.get(rowId);

        return (
          <div
            key={rowId}
            onClick={(e) => {
              e.stopPropagation();
              navigateToRow?.(rowId);
            }}
            className={'w-full cursor-pointer underline'}
          >
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
