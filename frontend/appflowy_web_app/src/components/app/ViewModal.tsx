import {
  CreateRowDoc,
  LoadView,
  LoadViewMeta,
  UpdatePagePayload,
  ViewComponentProps,
  ViewLayout,
  YDoc,
} from '@/application/types';
import { findView } from '@/components/_shared/outline/utils';
import { Popover } from '@/components/_shared/popover';
import { useAppHandlers, useAppOutline } from '@/components/app/app.hooks';
import DatabaseView from '@/components/app/DatabaseView';
import MorePageActions from '@/components/app/view-actions/MorePageActions';
import { Document } from '@/components/document';
import RecordNotFound from '@/components/error/RecordNotFound';
import { ViewMetaProps } from '@/components/view-meta';
import { Dialog, IconButton, Tooltip } from '@mui/material';
import React, { useCallback, useEffect, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as ExpandMoreIcon } from '$icons/16x/full_view.svg';
import { ReactComponent as MoreIcon } from '@/assets/more.svg';
import ShareButton from 'src/components/app/share/ShareButton';

function ViewModal ({
  viewId,
  open,
  onClose,
}: {
  viewId: string;
  open: boolean;
  onClose: () => void;
}) {
  const { t } = useTranslation();
  const {
    toView,
    loadViewMeta,
    createRowDoc,
    loadView,
    updatePage,
    addPage,
    deletePage,
    openPageModal,
  } = useAppHandlers();
  const outline = useAppOutline();
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

  const view = useMemo(() => {
    if (!outline || !viewId) return;
    return findView(outline, viewId);
  }, [outline, viewId]);

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

  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);

  const modalTitle = useMemo(() => {
    return (
      <div className={'w-full bg-bg-body z-[10] px-4 py-4 sticky top-0 flex items-center justify-between gap-2'}>
        <Tooltip title={t('tooltip.openAsPage')}>
          <IconButton
            size={'small'}
            onClick={() => {
              onClose();

              void toView(viewId);
            }}
          >
            <ExpandMoreIcon className={'text-text-title'} />
          </IconButton>
        </Tooltip>
        <div className={'flex items-center gap-4'}>
          <ShareButton viewId={viewId} />
          <Tooltip title={t('moreAction.moreOptions')}>
            <IconButton
              size={'small'}
              onClick={e => {
                setAnchorEl(e.currentTarget);
              }}
            >
              <MoreIcon />
            </IconButton>
          </Tooltip>
        </div>

      </div>
    );
  }, [onClose, t, toView, viewId]);

  const layout = view?.layout || ViewLayout.Document;

  const View = useMemo(() => {
    switch (layout) {
      case ViewLayout.Document:
        return Document;
      case ViewLayout.Grid:
      case ViewLayout.Board:
      case ViewLayout.Calendar:
        return DatabaseView;
      default:
        return null;
    }
  }, [layout]) as React.FC<ViewComponentProps>;

  const viewDom = useMemo(() => {

    if (!doc || !viewMeta) return null;
    return <View
      doc={doc}
      readOnly={false}
      viewMeta={viewMeta}
      navigateToView={toView}
      loadViewMeta={loadViewMeta}
      createRowDoc={createRowDoc}
      loadView={loadView}
      updatePage={updatePage}
      addPage={addPage}
      deletePage={deletePage}
      openPageModal={openPageModal}
    />;
  }, [openPageModal, doc, viewMeta, View, toView, loadViewMeta, createRowDoc, loadView, updatePage, addPage, deletePage]);
  const [paperVisible, setPaperVisible] = React.useState(false);

  return (
    <Dialog
      open={open}
      onClose={onClose}
      fullWidth={true}
      onTransitionEnd={() => {
        setPaperVisible(true);
      }}
      PaperProps={{
        className: `max-w-[70vw] flex flex-col h-[70vh] appflowy-scroller w-fit ${paperVisible ? 'visible' : 'hidden'}`,
      }}
    >
      {modalTitle}
      {notFound ? (
        <RecordNotFound />
      ) : (
        <div className={'w-full h-full'}>
          {viewDom}
        </div>
      )}
      {view && <Popover
        open={Boolean(anchorEl)}
        anchorEl={anchorEl}
        onClose={() => setAnchorEl(null)}
      >
        <MorePageActions
          view={view}
          onDeleted={() => {
            setAnchorEl(null);
          }}
          onMoved={() => {
            setAnchorEl(null);
          }}
        />
      </Popover>}

    </Dialog>
  );
}

export default ViewModal;