import { GetViewRowsMap, LoadView, LoadViewMeta, ViewLayout, YDoc } from '@/application/types';
import ViewHelmet from '@/components/_shared/helmet/ViewHelmet';
import PageSkeleton from '@/components/_shared/skeleton/PageSkeleton';
import { useAppHandlers, useAppOutline, useAppViewId } from '@/components/app/app.hooks';
import DatabaseView from '@/components/app/DatabaseView';
import RecordNotFound from '@/components/error/RecordNotFound';
import { findView } from '@/components/publish/header/utils';
import { ViewMetaProps } from '@/components/view-meta';
import React, { memo, useCallback, useEffect, useMemo } from 'react';
import { Document } from '@/components/document';

function AppPage () {
  const viewId = useAppViewId();
  const outline = useAppOutline();
  const {
    toView,
    loadViewMeta,
    getViewRowsMap,
    loadView,
  } = useAppHandlers();
  const view = useMemo(() => {
    if (!outline || !viewId) return;
    return findView(outline.children, viewId);
  }, [outline, viewId]);

  const helmet = useMemo(() => {
    return view ? <ViewHelmet name={view.name} icon={view.icon || undefined} /> : null;
  }, [view]);

  const [doc, setDoc] = React.useState<YDoc | undefined>(undefined);
  const [notFound, setNotFound] = React.useState(false);

  const loadPageDoc = useCallback(async () => {
    setNotFound(false);
    setDoc(undefined);
    if (!viewId) return;
    try {
      const doc = await loadView(viewId);

      setDoc(doc);
    } catch (e) {
      console.error(e);
      setNotFound(true);
    }
  }, [loadView, viewId]);

  useEffect(() => {
    void loadPageDoc();
  }, [loadPageDoc]);

  const View = useMemo(() => {
    switch (view?.layout) {
      case ViewLayout.Document:
        return Document;
      case ViewLayout.Grid:
      case ViewLayout.Board:
      case ViewLayout.Calendar:
        return DatabaseView;
      default:
        return null;
    }
  }, [view?.layout]) as React.FC<{
    doc: YDoc;
    navigateToView?: (viewId: string) => Promise<void>;
    loadViewMeta?: LoadViewMeta;
    getViewRowsMap?: GetViewRowsMap;
    loadView?: LoadView;
    viewMeta: ViewMetaProps;
  }>;

  const viewMeta: ViewMetaProps = useMemo(() => {
    return view ? {
      name: view.name,
      icon: view.icon || undefined,
      cover: view.extra?.cover || undefined,
      layout: view.layout,
      visibleViewIds: [],
      viewId: view.view_id,
    } : {};
  }, [view]);

  const viewDom = useMemo(() => {
    return doc && View ? (
      <View doc={doc} viewMeta={viewMeta} navigateToView={toView} loadViewMeta={loadViewMeta}
            getViewRowsMap={getViewRowsMap} loadView={loadView}
      />
    ) : (
      <PageSkeleton hasCover={!!viewMeta.cover} hasIcon={!!viewMeta.icon?.value} hasName />
    );
  }, [doc, View, viewMeta, toView, loadViewMeta, getViewRowsMap, loadView]);

  return (
    <div className={'relative w-full h-full'}>
      {helmet}

      {notFound ? (
        <RecordNotFound />
      ) : (
        <div className={'w-full h-full'}>
          {viewDom}
        </div>
      )}
    </div>
  );
}

export default memo(AppPage);