import { YDatabase, YDoc, YjsEditorKey } from '@/application/collab.type';
import {
  DatabaseContext,
  DatabaseContextState,
  getPrimaryFieldId,
  parseRelationTypeOption,
  useFieldSelector,
} from '@/application/database-yjs';
import { RelationCell, RelationCellData } from '@/application/database-yjs/cell.type';
import { ViewMeta } from '@/application/db/tables/view_metas';
import { RelationPrimaryValue } from '@/components/database/components/cell/relation/RelationPrimaryValue';
import { debounce } from 'lodash-es';
import React, { useCallback, useContext, useEffect, useMemo, useState } from 'react';

function RelationItems({ style, cell, fieldId }: { cell: RelationCell; fieldId: string; style?: React.CSSProperties }) {
  const viewId = useContext(DatabaseContext)?.iidIndex;
  const { field } = useFieldSelector(fieldId);
  const relatedDatabaseId = field ? parseRelationTypeOption(field).database_id : null;

  const getViewRowsMap = useContext(DatabaseContext)?.getViewRowsMap;
  const loadViewMeta = useContext(DatabaseContext)?.loadViewMeta;
  const loadView = useContext(DatabaseContext)?.loadView;

  const [noAccess, setNoAccess] = useState(false);
  const [relations, setRelations] = useState<Record<string, string> | null>();
  const [rows, setRows] = useState<DatabaseContextState['rowDocMap'] | null>();
  const [relatedFieldId, setRelatedFieldId] = useState<string | undefined>();
  const relatedViewId = relatedDatabaseId ? relations?.[relatedDatabaseId] : null;
  const [rowIds, setRowIds] = useState([] as string[]);

  // const navigateToRow = useNavigateToRow();

  useEffect(() => {
    if (!viewId) return;

    const update = (meta: ViewMeta) => {
      setRelations(meta.database_relations);
    };

    try {
      void loadViewMeta?.(viewId, update);
    } catch (e) {
      console.error(e);
    }
  }, [loadViewMeta, viewId]);

  const handleUpdateRowIds = useCallback(
    (rows: DatabaseContextState['rowDocMap']) => {
      const ids = (cell.data?.toJSON() as RelationCellData) ?? [];

      setRowIds(ids.filter((id) => rows?.has(id)));
    },
    [cell.data]
  );

  useEffect(() => {
    if (!relatedViewId || !getViewRowsMap || !relatedFieldId) return;
    void (async () => {
      try {
        const { rows } = await getViewRowsMap(relatedViewId);

        setRows(rows);
      } catch (e) {
        console.error(e);
      }
    })();
  });

  const debounceUpdateRowIds = useMemo(() => {
    return debounce(handleUpdateRowIds, 500);
  }, [handleUpdateRowIds]);

  useEffect(() => {
    if (!rows) return;
    debounceUpdateRowIds(rows);
  }, [rows, debounceUpdateRowIds]);

  useEffect(() => {
    const observerHandler = () => (rows ? handleUpdateRowIds(rows) : setRowIds([]));

    rows?.observe(observerHandler);
    return () => rows?.unobserve(observerHandler);
  }, [rows, handleUpdateRowIds]);

  useEffect(() => {
    if (!relatedViewId) return;

    void (async () => {
      try {
        const viewDoc = await loadView?.(relatedViewId);

        console.log('View not loaded, fetching view', relatedViewId);

        if (!viewDoc) {
          throw new Error('No access');
        }

        const database = viewDoc.getMap(YjsEditorKey.data_section).get(YjsEditorKey.database) as YDatabase;
        const fieldId = getPrimaryFieldId(database);

        setNoAccess(!fieldId);
        setRelatedFieldId(fieldId);
      } catch (e) {
        console.error(e);
        setNoAccess(true);
      }
    })();
  }, [loadView, relatedViewId]);

  return (
    <div style={style} className={'relation-cell flex w-full items-center gap-2'}>
      {noAccess ? (
        <div className={'text-text-caption'}>No access</div>
      ) : (
        rowIds.map((rowId) => {
          const rowDoc = rows?.get(rowId) as YDoc;

          return (
            <div
              key={rowId}
              // onClick={(e) => {
              //   e.stopPropagation();
              //   navigateToRow?.(rowId);
              // }}
              className={'underline'}
            >
              <RelationPrimaryValue fieldId={relatedFieldId} rowDoc={rowDoc} />
            </div>
          );
        })
      )}
    </div>
  );
}

export default RelationItems;
