import React, { useCallback, useMemo } from 'react';
import Collapse from '@mui/material/Collapse';
import { TransitionGroup } from 'react-transition-group';
import NestedPageTitle from '$app/components/layout/NestedPage/NestedPageTitle';
import { useLoadChildPages, usePageActions } from '$app/components/layout/NestedPage/NestedPage.hooks';
import { useDrag } from '$app/components/_shared/drag-block';
import { useAppDispatch } from '$app/stores/store';
import { movePageThunk } from '$app_reducers/pages/async_actions';

function NestedPage({ pageId }: { pageId: string }) {
  const { toggleCollapsed, collapsed, childPages } = useLoadChildPages(pageId);
  const { onAddPage, onPageClick, onDeletePage, onDuplicatePage, onRenamePage } = usePageActions(pageId);
  const dispatch = useAppDispatch();
  const children = useMemo(() => {
    return collapsed ? [] : childPages;
  }, [collapsed, childPages]);

  const onDragFinished = useCallback(
    (result: { dragId: string; position: 'before' | 'after' | 'inside' }) => {
      void dispatch(
        movePageThunk({
          sourceId: result.dragId,
          targetId: pageId,
          insertType: result.position,
        })
      );
    },
    [dispatch, pageId]
  );

  const { onDrop, dropPosition, onDragOver, onDragLeave, onDragStart, onDragEnd, isDraggingOver, isDragging } = useDrag({
    onEnd: onDragFinished,
    dragId: pageId,
  });

  const className = useMemo(() => {
    const defaultClassName = 'relative flex-1 flex flex-col w-full';

    if (isDragging) {
      return `${defaultClassName} opacity-40`;
    }

    if (isDraggingOver && dropPosition === 'inside') {
      if (dropPosition === 'inside') {
        return `${defaultClassName} bg-content-blue-100`;
      }
    } else {
      return defaultClassName;
    }
  }, [dropPosition, isDragging, isDraggingOver]);

  return (
    <div
      className={className}
      onDragLeave={onDragLeave}
      onDragStart={onDragStart}
      onDragOver={onDragOver}
      onDragEnd={onDragEnd}
      onDrop={onDrop}
      draggable={true}
      data-page-id={pageId}
    >
      <div
        style={{
          height: dropPosition === 'before' || dropPosition === 'after' ? '4px' : '0px',
          top: dropPosition === 'before' ? '-4px' : 'auto',
          bottom: dropPosition === 'after' ? '-4px' : 'auto',
        }}
        className={'pointer-events-none absolute left-0 z-10 w-full bg-content-blue-100'}
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
