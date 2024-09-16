import { GetViewRowsMap, LoadView, LoadViewMeta, YDoc } from '@/application/types';
import { findView } from '@/components/_shared/outline/utils';
import ComponentLoading from '@/components/_shared/progress/ComponentLoading';
import { useAppOutline } from '@/components/app/app.hooks';
import { Database } from '@/components/database';
import DatabaseHeader from '@/components/database/components/header/DatabaseHeader';
import { ViewMetaProps } from '@/components/view-meta';
import React, { Suspense, useCallback, useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';

function DatabaseView ({ viewMeta, ...props }: {
  doc: YDoc;
  navigateToView?: (viewId: string) => Promise<void>;
  loadViewMeta?: LoadViewMeta;
  getViewRowsMap?: GetViewRowsMap;
  loadView?: LoadView;
  viewMeta: ViewMetaProps;
}) {
  const [search, setSearch] = useSearchParams();
  const outline = useAppOutline();
  const iidIndex = viewMeta.viewId;
  const view = useMemo(() => {
    if (!outline || !iidIndex) return;
    return findView(outline || [], iidIndex);
  }, [outline, iidIndex]);

  const visibleViewIds = useMemo(() => view?.children?.map(v => v.view_id) || [], [view]);

  const viewId = useMemo(() => {
    return search.get('v') || iidIndex;
  }, [search, iidIndex]);

  const handleChangeView = useCallback(
    (viewId: string) => {
      setSearch(prev => {
        prev.set('v', viewId);
        return prev;
      });
    },
    [setSearch],
  );

  const handleNavigateToRow = useCallback(
    (rowId: string) => {
      setSearch(prev => {
        prev.set('r', rowId);
        return prev;
      });
    },
    [setSearch],
  );

  const rowId = search.get('r') || undefined;

  if (!viewId) return null;

  return (
    <div
      style={{
        minHeight: 'calc(100vh - 48px)',
      }}
      className={'relative flex h-full w-full flex-col px-6'}
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