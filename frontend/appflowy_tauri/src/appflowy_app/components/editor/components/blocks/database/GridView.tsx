import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Database, DatabaseRenderedProvider } from '$app/components/database';
import { ViewIdProvider } from '$app/hooks';

function GridView({ viewId }: { viewId: string }) {
  const [selectedViewId, onChangeSelectedViewId] = useState(viewId);

  const ref = useRef<HTMLDivElement>(null);

  const [rendered, setRendered] = useState<{ viewId: string; rendered: boolean } | undefined>(undefined);

  // delegate wheel event to layout when grid is scrolled to top or bottom
  useEffect(() => {
    const element = ref.current;

    const viewId = rendered?.viewId;

    if (!viewId || !element) {
      return;
    }

    const gridScroller = element.querySelector(`[data-view-id="${viewId}"] .grid-scroll-container`) as HTMLDivElement;

    const scrollLayout = gridScroller?.closest('.appflowy-scroll-container') as HTMLDivElement;

    if (!gridScroller || !scrollLayout) {
      return;
    }

    const onWheel = (event: WheelEvent) => {
      const deltaY = event.deltaY;
      const deltaX = event.deltaX;

      if (Math.abs(deltaX) > 8) {
        return;
      }

      const { scrollTop, scrollHeight, clientHeight } = gridScroller;

      const atTop = deltaY < 0 && scrollTop === 0;
      const atBottom = deltaY > 0 && scrollTop + clientHeight >= scrollHeight;

      // if at top or bottom, prevent default to allow layout to scroll
      if (atTop || atBottom) {
        scrollLayout.scrollTop += deltaY;
      }
    };

    gridScroller.addEventListener('wheel', onWheel, { passive: false });
    return () => {
      gridScroller.removeEventListener('wheel', onWheel);
    };
  }, [rendered]);

  const onRendered = useCallback((viewId: string) => {
    setRendered({
      viewId,
      rendered: true,
    });
  }, []);

  return (
    <ViewIdProvider value={viewId}>
      <DatabaseRenderedProvider value={onRendered}>
        <Database ref={ref} selectedViewId={selectedViewId} setSelectedViewId={onChangeSelectedViewId} />
      </DatabaseRenderedProvider>
    </ViewIdProvider>
  );
}

export default React.memo(GridView);
