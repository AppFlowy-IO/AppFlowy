import { UIVariant, ViewComponentProps, ViewLayout, ViewMetaProps, YDoc } from '@/application/types';
import Help from '@/components/_shared/help/Help';
import { notify } from '@/components/_shared/notify';
import { findView } from '@/components/_shared/outline/utils';
import { ReactComponent as TipIcon } from '@/assets/warning.svg';
import { AppContext, useAppHandlers, useAppOutline, useAppViewId } from '@/components/app/app.hooks';
import DatabaseView from '@/components/app/DatabaseView';
import { Document } from '@/components/document';
import RecordNotFound from '@/components/error/RecordNotFound';
import { getPlatform } from '@/utils/platform';
import { desktopDownloadLink, openAppFlowySchema } from '@/utils/url';
import { Button, Checkbox, FormControlLabel } from '@mui/material';
import React, { lazy, memo, Suspense, useCallback, useContext, useEffect, useMemo } from 'react';

const ViewHelmet = lazy(() => import('@/components/_shared/helmet/ViewHelmet'));

function AppPage () {
  const viewId = useAppViewId();
  const outline = useAppOutline();
  const ref = React.useRef<HTMLDivElement>(null);

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
  const loadPageDoc = useCallback(async (id: string) => {

    setNotFound(false);
    setDoc(undefined);
    try {
      const doc = await loadView(id);

      setDoc(doc);
    } catch (e) {
      setNotFound(true);
      console.error(e);
    }

  }, [loadView]);

  useEffect(() => {
    if (!viewId) return;

    void loadPageDoc(viewId);
  }, [loadPageDoc, viewId]);

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
        variant={UIVariant.App}
      />
    ) : null;
  }, [addPage, handleUploadFile, loadViews, setWordCount, openPageModal, deletePage, updatePage, onRendered, doc, viewMeta, View, toView, loadViewMeta, createRowDoc, appendBreadcrumb, loadView]);

  useEffect(() => {
    if (!View || !viewId || !doc) return;
    localStorage.setItem('last_view_id', viewId);
  }, [View, viewId, doc]);

  const layout = view?.layout;

  useEffect(() => {
    if (layout !== undefined && layout !== ViewLayout.Document && !localStorage.getItem('open_edit_tip')) {
      notify.clear();
      notify.info({
        autoHideDuration: null,
        type: 'info',
        title: 'Edit in app',
        message: <div className={'w-full gap-2 flex flex-col items-start'}>
          <div>{`Editing databases is supported in AppFlowy's desktop and mobile apps`}
          </div>
          <div className={'text-sm flex items-center gap-2 text-text-caption'}>
            <TipIcon className={'h-4 w-4 text-function-warning'} />
            Don't have AppFlowy? <a
            className={'text-fill-default hover:underline'}
            href={desktopDownloadLink}
          >Download</a></div>
          <div className={'flex items-center max-sm:my-4 max-sm:flex-col mt-2 w-full justify-between'}>
            <FormControlLabel
              className={' max-sm:w-full'}
              value="end"
              onChange={(_e, value) => {
                if (value) {
                  localStorage.setItem('open_edit_tip', 'true');
                } else {
                  localStorage.removeItem('open_edit_tip');
                }
              }}
              control={<Checkbox />}
              label="Don't remind me again"
            />
            <Button
              color={'primary'}
              className={'max-sm:w-full max-sm:py-4 max-sm:text-base'}
              onClick={() => window.open(openAppFlowySchema, '_current')}
              variant={'contained'}
            >
              Open in AppFlowy
            </Button>
          </div>
        </div>,
        showActions: false,
      });
    }
  }, [layout]);

  if (!viewId) return null;
  return (
    <div
      ref={ref}
      className={'relative w-full h-full'}
    >
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