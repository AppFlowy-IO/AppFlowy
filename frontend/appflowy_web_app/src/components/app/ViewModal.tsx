import {
  ViewComponentProps,
  ViewLayout,
  YDoc,
  ViewMetaProps,
} from '@/application/types';
import SpaceIcon from '@/components/_shared/breadcrumb/SpaceIcon';
import { findAncestors, findView } from '@/components/_shared/outline/utils';
import { useAppHandlers, useAppOutline } from '@/components/app/app.hooks';
import DatabaseView from '@/components/app/DatabaseView';
import MoreActions from '@/components/app/header/MoreActions';
import MovePagePopover from '@/components/app/view-actions/MovePagePopover';
import { Document } from '@/components/document';
import RecordNotFound from '@/components/error/RecordNotFound';
import { Button, Dialog, Divider, IconButton, Tooltip, Zoom } from '@mui/material';
import React, { useCallback, useEffect, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as ExpandMoreIcon } from '$icons/16x/full_view.svg';
import ShareButton from 'src/components/app/share/ShareButton';
import { ReactComponent as CloseIcon } from '@/assets/close.svg';
import { ReactComponent as ArrowRightIcon } from '@/assets/arrow_right.svg';
import { TransitionProps } from '@mui/material/transitions';

const Transition = React.forwardRef(function Transition (
  props: TransitionProps & {
    children: React.ReactElement;
  },
  ref: React.Ref<unknown>,
) {
  return <Zoom

    ref={ref}
    {...props}
  />;
});

function ViewModal ({
  viewId,
  open,
  onClose,
}: {
  viewId?: string;
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
    loadViews,
    setWordCount,
    uploadFile,
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
  const handleUploadFile = useCallback((file: File) => {
    if (view && uploadFile) {
      return uploadFile(view.view_id, file);
    }

    return Promise.reject();
  }, [uploadFile, view]);
  const [movePopoverAnchorEl, setMovePopoverAnchorEl] = React.useState<null | HTMLElement>(null);

  const onMoved = useCallback(() => {
    setMovePopoverAnchorEl(null);
  }, []);

  const modalTitle = useMemo(() => {
    if (!viewId) return null;
    const space = findAncestors(outline || [], viewId)?.find(item => item.extra?.is_space);

    return (
      <div className={'w-full bg-bg-body z-[10] px-4 py-4 sticky top-0 flex items-center justify-between gap-2'}>
        <div className={'flex items-center gap-4'}>
          <Tooltip title={t('tooltip.openAsPage')}>
            <IconButton
              size={'small'}
              onClick={async () => {
                await toView(viewId);
                onClose();
              }}
            >
              <ExpandMoreIcon className={'text-text-title opacity-80 h-5 w-5'} />
            </IconButton>
          </Tooltip>
          <Divider
            orientation={'vertical'}
            className={'h-4'}
          />
          {space && (
            <Button
              onClick={(e) => {
                setMovePopoverAnchorEl(e.currentTarget);
              }}
              size={'small'}
              startIcon={<SpaceIcon
                bgColor={space.extra?.space_icon_color}
                value={space.extra?.space_icon || ''}
                char={space.extra?.space_icon ? undefined : space.name.slice(0, 1)}
              />}
              color={'inherit'}
              className={'justify-start px-1.5'}
              endIcon={<ArrowRightIcon className={'transform rotate-90'} />}
            >{space.name}</Button>
          )}
        </div>

        <div className={'flex items-center gap-4'}>
          <ShareButton viewId={viewId} />
          <MoreActions
            onDeleted={() => {
              onClose();
            }}
            viewId={viewId}
          />

          <Divider
            orientation={'vertical'}
            className={'h-4'}
          />
          <IconButton
            size={'small'}
            onClick={onClose}
          >
            <CloseIcon />
          </IconButton>
        </div>

      </div>
    );
  }, [onClose, outline, t, toView, viewId]);

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
      loadViews={loadViews}
      onWordCountChange={setWordCount}
      uploadFile={handleUploadFile}
    />;
  }, [openPageModal, handleUploadFile, setWordCount, loadViews, doc, viewMeta, View, toView, loadViewMeta, createRowDoc, loadView, updatePage, addPage, deletePage]);

  return (
    <Dialog
      open={open}
      onClose={onClose}
      fullWidth={true}
      TransitionComponent={Transition}
      PaperProps={{
        className: `max-w-[70vw] w-[1188px] flex flex-col h-[80vh] appflowy-scroller`,
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
      {viewId && <MovePagePopover
        viewId={viewId}
        open={Boolean(movePopoverAnchorEl)}
        anchorEl={movePopoverAnchorEl}
        onClose={() => setMovePopoverAnchorEl(null)}
        onMoved={onMoved}
      />}

    </Dialog>
  );
}

export default ViewModal;