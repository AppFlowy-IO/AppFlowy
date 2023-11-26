import React, { useEffect, useRef, useState } from 'react';
import { BlockType, NestedBlock } from '$app/interfaces/document';
import { Database } from '$app/components/database';
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
    <div className='flex h-[400px] overflow-hidden py-3 caret-text-title' ref={ref}>
      <ViewIdProvider value={viewId}>
        <Database selectedViewId={selectedViewId} setSelectedViewId={onChangeSelectedViewId} />
      </ViewIdProvider>
    </div>
  );
}

export default React.memo(GridBlock);
