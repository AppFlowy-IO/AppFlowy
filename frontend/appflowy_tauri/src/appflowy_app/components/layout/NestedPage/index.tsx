import React, { useEffect, useState } from 'react';

import NestedPageTitle from '$app/components/layout/NestedPage/NestedPageTitle';
import { useLoadChildPages, usePageActions } from '$app/components/layout/NestedPage/NestedPage.hooks';

const COLLAPSED_DURATION = 50;
const EXPANDED_DURATION = 300;
const ITEM_HEIGHT = 38;

function NestedPage({ pageId }: { pageId: string }) {
  const { toggleCollapsed, collapsed, childPages } = useLoadChildPages(pageId);
  const { onAddPage, onPageClick, onDeletePage, onDuplicatePage, onRenamePage } = usePageActions(pageId);

  const [height, setHeight] = useState<string | number>(0);

  useEffect(() => {
    const length = childPages?.length || 0;

    setHeight(length * ITEM_HEIGHT);
    if (collapsed) {
      setTimeout(() => {
        setHeight(0);
      }, COLLAPSED_DURATION);
    } else {
      setTimeout(() => {
        setHeight('auto');
      }, EXPANDED_DURATION);
    }
  }, [childPages?.length, collapsed]);

  return (
    <div>
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
      <div
        style={{
          height,
          overflow: 'hidden',
          transition: `height 200ms ease-in-out`,
        }}
        className={'pl-4'}
      >
        {childPages?.map((pageId) => (
          <NestedPage key={pageId} pageId={pageId} />
        ))}
      </div>
    </div>
  );
}

export default NestedPage;
