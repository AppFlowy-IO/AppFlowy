import { AppendBreadcrumb, CreateRowDoc, LoadView, LoadViewMeta, ViewLayout, YDoc } from '@/application/types';
import Help from '@/components/_shared/help/Help';
import { findView } from '@/components/_shared/outline/utils';
import CalendarSkeleton from '@/components/_shared/skeleton/CalendarSkeleton';
import DocumentSkeleton from '@/components/_shared/skeleton/DocumentSkeleton';
import GridSkeleton from '@/components/_shared/skeleton/GridSkeleton';
import KanbanSkeleton from '@/components/_shared/skeleton/KanbanSkeleton';
import { AppContext, useAppHandlers, useAppOutline, useAppViewId } from '@/components/app/app.hooks';
import DatabaseView from '@/components/app/DatabaseView';
import { Document } from '@/components/document';
import RecordNotFound from '@/components/error/RecordNotFound';
import { ViewMetaProps } from '@/components/view-meta';
import React, { lazy, memo, Suspense, useCallback, useContext, useEffect, useMemo } from 'react';

const ViewHelmet = lazy(() => import('@/components/_shared/helmet/ViewHelmet'));

function AppPage () {
  const viewId = useAppViewId();
  const outline = useAppOutline();
  const {
    toView,
    loadViewMeta,
    createRowDoc,
    loadView,
    appendBreadcrumb,
    onRendered,
  } = useAppHandlers();
  const view = useMemo(() => {
    if (!outline || !viewId) return;
    return findView(outline, viewId);
  }, [outline, viewId]);
  const rendered = useContext(AppContext)?.rendered;

  const helmet = useMemo(() => {
    return view && rendered ? <Suspense><ViewHelmet
      name={view.name}
      icon={view.icon || undefined}
    /></Suspense> : null;
  }, [rendered, view]);

  const [doc, setDoc] = React.useState<YDoc | undefined>(undefined);
  const [notFound, setNotFound] = React.useState(false);
  const loadPageDoc = useCallback(async () => {

    if (!viewId) {
      return;
    }

    setNotFound(false);
    setDoc(undefined);
    try {
      const doc = await loadView(viewId);

      setDoc(doc);
    } catch (e) {
      setNotFound(true);
      console.error(e);
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
    readOnly: boolean;
    navigateToView?: (viewId: string, blockId?: string) => Promise<void>;
    loadViewMeta?: LoadViewMeta;
    createRowDoc?: CreateRowDoc;
    loadView?: LoadView;
    viewMeta: ViewMetaProps;
    appendBreadcrumb?: AppendBreadcrumb;
    onRendered?: () => void;
  }>;

  const viewMeta: ViewMetaProps | null = useMemo(() => {
    return view ? {
      name: view.name,
      icon: view.icon || undefined,
      cover: view.extra?.cover || undefined,
      layout: view.layout,
      visibleViewIds: [],
      viewId: view.view_id,
    } : null;
  }, [view]);

  const skeleton = useMemo(() => {
    if (!viewMeta) {
      return null;
    }

    switch (viewMeta.layout) {
      case ViewLayout.Document:
        return <DocumentSkeleton />;
      case ViewLayout.Grid:
        return <GridSkeleton />;
      case ViewLayout.Board:
        return <KanbanSkeleton />;
      case ViewLayout.Calendar:
        return <CalendarSkeleton />;
      default:
        return null;
    }

  }, [viewMeta]);

  const viewDom = useMemo(() => {

    return doc && viewMeta && View ? (
      <View
        doc={doc}
        readOnly={true}
        viewMeta={viewMeta}
        navigateToView={toView}
        loadViewMeta={loadViewMeta}
        createRowDoc={createRowDoc}
        appendBreadcrumb={appendBreadcrumb}
        loadView={loadView}
        onRendered={onRendered}
      />
    ) : skeleton;
  }, [onRendered, doc, viewMeta, View, toView, loadViewMeta, createRowDoc, appendBreadcrumb, loadView, skeleton]);

  useEffect(() => {
    if (!View || !viewId || !doc) return;
    localStorage.setItem('last_view_id', viewId);
  }, [View, viewId, doc]);

  if (!viewId) return null;
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
      {view && doc && <Help />}

    </div>
  );
}

export default memo(AppPage);