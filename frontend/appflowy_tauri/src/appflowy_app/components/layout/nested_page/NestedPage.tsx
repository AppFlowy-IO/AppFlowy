import React, { useCallback, useMemo } from 'react';
import Collapse from '@mui/material/Collapse';
import { TransitionGroup } from 'react-transition-group';
import NestedPageTitle from '$app/components/layout/nested_page/NestedPageTitle';
import { useLoadChildPages, usePageActions } from '$app/components/layout/nested_page/NestedPage.hooks';
import { useDrag } from 'src/appflowy_app/components/_shared/drag_block';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { movePageThunk } from '$app_reducers/pages/async_actions';
import { ViewLayoutPB } from '@/services/backend';

function NestedPage({ pageId }: { pageId: string }) {
  const { toggleCollapsed, collapsed, childPages } = useLoadChildPages(pageId);
  const { onAddPage, onPageClick, onDeletePage, onDuplicatePage, onRenamePage } = usePageActions(pageId);
  const dispatch = useAppDispatch();
  const { page, parentLayout } = useAppSelector((state) => {
    const page = state.pages.pageMap[pageId];
    const parent = state.pages.pageMap[page?.parentId || ''];

    return {
      page,
      parentLayout: parent?.layout,
    };
  });

  const disableChildren = useAppSelector((state) => {
    if (!page) return true;
    const layout = state.pages.pageMap[page.parentId]?.layout;

    return !(layout === undefined || layout === ViewLayoutPB.Document);
  });
  const children = useMemo(() => {
    if (disableChildren) {
      return [];
    }

    return collapsed ? [] : childPages;
  }, [collapsed, childPages, disableChildren]);

  const onDragFinished = useCallback(
    (result: { dragId: string; position: 'before' | 'after' | 'inside' }) => {
      const { dragId, position } = result;

      if (dragId === pageId) return;
      if (position === 'inside' && page?.layout !== ViewLayoutPB.Document) return;
      void dispatch(
        movePageThunk({
          sourceId: dragId,
          targetId: pageId,
          insertType: position,
        })
      );
    },
    [dispatch, page?.layout, pageId]
  );

  const { onDrop, dropPosition, onDragOver, onDragLeave, onDragStart, onDragEnd, isDraggingOver, isDragging } = useDrag({
    onEnd: onDragFinished,
    dragId: pageId,
  });

  const className = useMemo(() => {
    const defaultClassName = 'relative flex-1 select-none flex flex-col w-full';

    if (isDragging) {
      return `${defaultClassName} opacity-40`;
    }

    if (isDraggingOver && dropPosition === 'inside' && page?.layout === ViewLayoutPB.Document) {
      if (dropPosition === 'inside') {
        return `${defaultClassName} bg-content-blue-100`;
      }
    } else {
      return defaultClassName;
    }
  }, [dropPosition, isDragging, isDraggingOver, page?.layout]);

  // Only allow dragging if the parent layout is undefined or a document
  const draggable = parentLayout === undefined || parentLayout === ViewLayoutPB.Document;

  return (
    <div
      className={className}
      onDragLeave={onDragLeave}
      onDragStart={onDragStart}
      onDragOver={onDragOver}
      onDragEnd={onDragEnd}
      onDrop={onDrop}
      draggable={draggable}
      data-drop-enabled={page?.layout === ViewLayoutPB.Document}
      data-dragging={isDragging}
      data-page-id={pageId}
    >
      <div
        style={{
          height: dropPosition === 'before' || dropPosition === 'after' ? '2px' : '0px',
          top: dropPosition === 'before' ? '-2px' : 'auto',
          bottom: dropPosition === 'after' ? '-2px' : 'auto',
        }}
        className={'pointer-events-none absolute left-0 z-10 w-full bg-content-blue-300'}
      />
      <NestedPageTitle
        onClick={() => {
          onPageClick();
        }}
        onAddPage={onAddPage}
        onDuplicate={onDuplicatePage}
        onDelete={onDeletePage}
        onRename={onRenamePage}
        collapsed={collapsed}
        toggleCollapsed={toggleCollapsed}
        pageId={pageId}
      />
      <div className={'pl-4 pt-[2px]'}>
        <TransitionGroup>
          {children?.map((pageId) => (
            <Collapse key={pageId}>
              <NestedPage key={pageId} pageId={pageId} />
            </Collapse>
          ))}
        </TransitionGroup>
      </div>
    </div>
  );
}

export default React.memo(NestedPage);
