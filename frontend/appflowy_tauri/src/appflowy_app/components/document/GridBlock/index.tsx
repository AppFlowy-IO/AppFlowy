import React, { useEffect, useRef, useState } from 'react';
import { BlockType, NestedBlock } from '$app/interfaces/document';
import { Database, VerticalScrollElementProvider } from '$app/components/database';
import { ViewIdProvider } from '@/appflowy_app/hooks';

function GridBlock({ node }: { node: NestedBlock<BlockType.GridBlock> }) {
  const viewId = node.data.viewId;
  const ref = useRef<HTMLDivElement>(null);
  const [selectedViewId, onChangeSelectedViewId] = useState(viewId);

  useEffect(() => {
    const element = ref.current;

    if (!element) return;

    const resizeObserver = new ResizeObserver(() => {
      element.style.minHeight = `${element.clientHeight}px`;
    });

    resizeObserver.observe(element);

    return () => {
      resizeObserver.disconnect();
    };
  }, []);

  return (
    <div className='max-h-[400px] overflow-y-auto py-3 caret-text-title' ref={ref}>
      <VerticalScrollElementProvider value={ref}>
        <ViewIdProvider value={viewId}>
          <Database selectedViewId={selectedViewId} setSelectedViewId={onChangeSelectedViewId} />
        </ViewIdProvider>
      </VerticalScrollElementProvider>
    </div>
  );
}

export default GridBlock;
