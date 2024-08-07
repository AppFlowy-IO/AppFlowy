import { GetViewRowsMap, LoadView, LoadViewMeta, YDoc } from '@/application/collab.type';
import ComponentLoading from '@/components/_shared/progress/ComponentLoading';
import { Database } from '@/components/database';
import DatabaseHeader from '@/components/database/components/header/DatabaseHeader';
import { ViewMetaProps } from '@/components/view-meta';
import React, { Suspense, useCallback, useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';

export interface DatabaseProps {
  doc: YDoc;
  getViewRowsMap?: GetViewRowsMap;
  loadView?: LoadView;
  navigateToView?: (viewId: string) => Promise<void>;
  loadViewMeta?: LoadViewMeta;
  viewMeta: ViewMetaProps;
}

function DatabaseView({ viewMeta, ...props }: DatabaseProps) {
  const [search, setSearch] = useSearchParams();
  const visibleViewIds = useMemo(() => viewMeta.visibleViewIds || [], [viewMeta]);

  const iidIndex = viewMeta.viewId;
  const viewId = useMemo(() => {
    return search.get('v') || iidIndex;
  }, [search, iidIndex]);

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
        minHeight: 'calc(100vh - 48px)',
      }}
      className={'relative flex h-full w-full flex-col px-16 max-md:px-4'}
    >
      <DatabaseHeader {...viewMeta} />
      <Suspense fallback={<ComponentLoading />}>
        <Database
          iidName={viewMeta.name || ''}
          iidIndex={iidIndex || ''}
          {...props}
          viewId={viewId}
          rowId={rowId}
          visibleViewIds={visibleViewIds}
          onChangeView={handleChangeView}
          onOpenRow={handleNavigateToRow}
        />
      </Suspense>
    </div>
  );
}

export default DatabaseView;
