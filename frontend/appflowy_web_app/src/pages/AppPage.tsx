import {
  ViewComponentProps,
  ViewLayout,
  YDoc,
  ViewMetaProps,
} from '@/application/types';
import Help from '@/components/_shared/help/Help';
import { findView } from '@/components/_shared/outline/utils';

import { AppContext, useAppHandlers, useAppOutline, useAppViewId } from '@/components/app/app.hooks';
import DatabaseView from '@/components/app/DatabaseView';
import { Document } from '@/components/document';
import RecordNotFound from '@/components/error/RecordNotFound';
import { getPlatform } from '@/utils/platform';
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
    updatePage,
    addPage,
    deletePage,
    openPageModal,
    loadViews,
    setWordCount,
    uploadFile,
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
  }, [view?.layout]) as React.FC<ViewComponentProps>;

  const viewMeta: ViewMetaProps | null = useMemo(() => {
    return view ? {
      name: view.name,
      icon: view.icon || undefined,
      cover: view.extra?.cover || undefined,
      layout: view.layout,
      visibleViewIds: [],
      viewId: view.view_id,
      extra: view.extra,
    } : null;
  }, [view]);

  const handleUploadFile = useCallback((file: File) => {
    if (view && uploadFile) {
      return uploadFile(view.view_id, file);
    }

    return Promise.reject();
  }, [uploadFile, view]);

  const viewDom = useMemo(() => {
    const isMobile = getPlatform().isMobile;

    return doc && viewMeta && View ? (
      <View
        doc={doc}
        readOnly={Boolean(isMobile)}
        viewMeta={viewMeta}
        navigateToView={toView}
        loadViewMeta={loadViewMeta}
        createRowDoc={createRowDoc}
        appendBreadcrumb={appendBreadcrumb}
        loadView={loadView}
        onRendered={onRendered}
        updatePage={updatePage}
        addPage={addPage}
        deletePage={deletePage}
        openPageModal={openPageModal}
        loadViews={loadViews}
        onWordCountChange={setWordCount}
        uploadFile={handleUploadFile}
      />
    ) : null;
  }, [addPage, handleUploadFile, loadViews, setWordCount, openPageModal, deletePage, updatePage, onRendered, doc, viewMeta, View, toView, loadViewMeta, createRowDoc, appendBreadcrumb, loadView]);

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