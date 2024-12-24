import { View, ViewLayout } from '@/application/types';
import PageActions from '@/components/app/view-actions/PageActions';
import SpaceActions from '@/components/app/view-actions/SpaceActions';
import React, { useCallback, useMemo } from 'react';
import { useAppHandlers } from '@/components/app/app.hooks';
import { notify } from '@/components/_shared/notify';

export function ViewActions({ view, hovered, setPopoverType, setAnchorPosition, setPopoverView }: {
  view: View;
  hovered?: boolean;
  setPopoverType: (popoverType: {
    category: 'space' | 'page';
    type: 'more' | 'add';
  }) => void;
  setAnchorPosition: (position: { top: number; left: number }) => void;
  setPopoverView: (view: View) => void;
}) {
  const isSpace = view?.extra?.is_space;

  const {
    addPage,
    openPageModal,
  } = useAppHandlers();
  const handleAddPage = useCallback(async (layout: ViewLayout, name?: string) => {
    if (!addPage || !openPageModal) return;
    try {
      const viewId = await addPage(view.view_id, { layout, name });

      openPageModal(viewId);
      // eslint-disable-next-line
    } catch (e: any) {
      notify.error(e.message);
    }

  }, [addPage, openPageModal, view.view_id]);

  const handleClick = useCallback((e: React.MouseEvent, popoverType: {
    category: 'space' | 'page';
    type: 'more' | 'add';
  }) => {
    setPopoverType(popoverType);
    const rect = (e.target as HTMLElement).getBoundingClientRect();

    setPopoverView(view);
    setAnchorPosition({ top: rect.bottom, left: rect.left });
  }, [setAnchorPosition, setPopoverType, setPopoverView, view]);

  const renderButton = useMemo(() => {
    if (!hovered || !view) return null;
    if (isSpace) return <SpaceActions
      onClickAdd={async () => {
        // handleClick(e, { category: 'space', type: 'add' });
        await handleAddPage(ViewLayout.Document);
      }}
      onClickMore={(e) => {
        handleClick(e, { category: 'space', type: 'more' });
      }}
      view={view}
    />;
    return <PageActions
      onClickAdd={async () => {
        // handleClick(e, { category: 'page', type: 'add' });
        await handleAddPage(ViewLayout.Document);
      }}
      onClickMore={(e) => {
        handleClick(e, { category: 'page', type: 'more' });
      }}
      view={view}
    />;
  }, [handleClick, hovered, isSpace, view, handleAddPage]);

  return <div onClick={e => e.stopPropagation()}>
    {renderButton}

  </div>;

}

export default ViewActions;