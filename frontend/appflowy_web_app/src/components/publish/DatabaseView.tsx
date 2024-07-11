import { YDoc } from '@/application/collab.type';
import { ViewMeta } from '@/application/db/tables/view_metas';
import { Database } from '@/components/database';
import DatabaseHeader from '@/components/database/components/header/DatabaseHeader';
import { ViewMetaProps } from '@/components/view-meta';
import React, { useCallback } from 'react';
import { useSearchParams } from 'react-router-dom';
import * as Y from 'yjs';

export interface DatabaseProps {
  doc: YDoc;
  getViewRowsMap?: (viewId: string, rowIds?: string[]) => Promise<{ rows: Y.Map<YDoc>; destroy: () => void }>;
  loadView?: (viewId: string) => Promise<YDoc>;
  navigateToView?: (viewId: string) => Promise<void>;
  loadViewMeta?: (viewId: string) => Promise<ViewMeta>;
  viewMeta: ViewMetaProps;
}

function DatabaseView({ viewMeta, ...props }: DatabaseProps) {
  const [search, setSearch] = useSearchParams();

  const viewId = search.get('v') || viewMeta.viewId;

  const handleChangeView = useCallback(
    (viewId: string) => {
      setSearch({ v: viewId });
    },
    [setSearch]
  );

  const handleNavigateToRow = useCallback(
    (rowId: string) => {
      setSearch({ r: rowId });
    },
    [setSearch]
  );

  const rowId = search.get('r') || undefined;

  if (!viewId) return null;

  return (
    <div
      style={{
        height: 'calc(100vh - 48px)',
      }}
      className={'relative flex h-full w-full flex-col'}
    >
      <DatabaseHeader {...viewMeta} />
      <Database
        iidName={viewMeta.name || ''}
        {...props}
        viewId={viewId}
        rowId={rowId}
        onChangeView={handleChangeView}
        onOpenRow={handleNavigateToRow}
      />
    </div>
  );
}

export default DatabaseView;
