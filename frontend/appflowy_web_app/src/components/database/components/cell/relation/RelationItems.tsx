import { YjsDatabaseKey } from '@/application/collab.type';
import { DatabaseContext, DatabaseContextState, useDatabase, useNavigateToRow } from '@/application/database-yjs';
import { RelationCell, RelationCellData } from '@/application/database-yjs/cell.type';
import { RelationPrimaryValue } from '@/components/database/components/cell/relation/RelationPrimaryValue';
import React, { useContext, useEffect, useMemo, useState } from 'react';

function RelationItems({ style, cell }: { cell: RelationCell; fieldId: string; style?: React.CSSProperties }) {
  const database = useDatabase();
  const viewId = database.get(YjsDatabaseKey.metas)?.get(YjsDatabaseKey.iid)?.toString();
  const rowIds = useMemo(() => {
    return (cell.data?.toJSON() as RelationCellData) ?? [];
  }, [cell.data]);
  const getViewRowsMap = useContext(DatabaseContext)?.getViewRowsMap;

  const [rows, setRows] = useState<DatabaseContextState['rowDocMap'] | null>();

  const navigateToRow = useNavigateToRow();

  useEffect(() => {
    if (!viewId || !rowIds.length) return;

    void getViewRowsMap?.(viewId, rowIds).then(({ rows }) => {
      setRows(rows);
    });
  }, [getViewRowsMap, rowIds, viewId]);

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
            {rowDoc && <RelationPrimaryValue rowDoc={rowDoc} />}
          </div>
        );
      })}
    </div>
  );
}

export default RelationItems;
