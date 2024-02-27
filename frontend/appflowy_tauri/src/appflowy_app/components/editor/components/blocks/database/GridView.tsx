import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Database, DatabaseRenderedProvider } from '$app/components/database';
import { ViewIdProvider } from '$app/hooks';

function GridView({ viewId }: { viewId: string }) {
  const [selectedViewId, onChangeSelectedViewId] = useState(viewId);

  const ref = useRef<HTMLDivElement>(null);

  const [rendered, setRendered] = useState(false);

  // delegate wheel event to layout when grid is scrolled to top or bottom
  useEffect(() => {
    const element = ref.current;

    if (!element) {
      return;
    }

    const gridScroller = element.querySelector('.grid-scroll-container') as HTMLDivElement;

    const scrollLayout = gridScroller?.closest('.appflowy-scroll-container') as HTMLDivElement;

    if (!gridScroller || !scrollLayout) {
      return;
    }

    const onWheel = (event: WheelEvent) => {
      const deltaY = event.deltaY;
      const deltaX = event.deltaX;

      if (deltaX > 10) {
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

  const onRendered = useCallback(() => {
    setRendered(true);
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
