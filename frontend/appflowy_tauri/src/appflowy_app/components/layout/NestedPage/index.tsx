import React, { useMemo } from 'react';
import Collapse from '@mui/material/Collapse';
import { TransitionGroup } from 'react-transition-group';
import NestedPageTitle from '$app/components/layout/NestedPage/NestedPageTitle';
import { useLoadChildPages, usePageActions } from '$app/components/layout/NestedPage/NestedPage.hooks';

function NestedPage({ pageId }: { pageId: string }) {
  const { toggleCollapsed, collapsed, childPages } = useLoadChildPages(pageId);
  const { onAddPage, onPageClick, onDeletePage, onDuplicatePage, onRenamePage } = usePageActions(pageId);

  const children = useMemo(() => {
    return collapsed ? [] : childPages;
  }, [collapsed, childPages]);

  return (
    <>
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
    </>
  );
}

export default React.memo(NestedPage);
