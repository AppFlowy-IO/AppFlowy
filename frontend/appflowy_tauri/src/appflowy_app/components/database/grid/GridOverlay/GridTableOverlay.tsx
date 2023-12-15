import React, { useEffect, useState } from 'react';
import GridRowContextMenu from '$app/components/database/grid/GridRowActions/GridRowContextMenu';
import GridRowActions from '$app/components/database/grid/GridRowActions/GridRowActions';

import { useGridTableHoverState } from '$app/components/database/grid/GridRowActions/GridRowActions.hooks';

function GridTableOverlay({
  containerRef,
  getScrollElement,
}: {
  containerRef: React.MutableRefObject<HTMLDivElement | null>;
  getScrollElement: () => HTMLDivElement | null;
}) {
  const [hoverRowTop, setHoverRowTop] = useState<string | undefined>();

  const { hoverRowId } = useGridTableHoverState(containerRef);

  useEffect(() => {
    const container = containerRef.current;

    if (!container) return;

    const cell = container.querySelector(`[data-key="row:${hoverRowId}"]`);

    if (!cell) return;
    const top = (cell as HTMLDivElement).style.top;

    setHoverRowTop(top);
  }, [containerRef, hoverRowId]);

  return (
    <div className={'absolute left-0 top-0'}>
      <GridRowActions
        getScrollElement={getScrollElement}
        containerRef={containerRef}
        rowId={hoverRowId}
        rowTop={hoverRowTop}
      />
      <GridRowContextMenu containerRef={containerRef} hoverRowId={hoverRowId} />
    </div>
  );
}

export default GridTableOverlay;
