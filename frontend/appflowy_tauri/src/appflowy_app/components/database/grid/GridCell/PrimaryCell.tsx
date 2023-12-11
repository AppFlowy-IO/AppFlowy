import React, { Suspense, useMemo, useRef } from 'react';
import { ReactComponent as OpenIcon } from '$app/assets/open.svg';
import { IconButton } from '@mui/material';

import { useGridTableHoverState } from '$app/components/database/grid/GridRowActions/GridRowActions.hooks';

function PrimaryCell({
  onEditRecord,
  icon,
  getContainerRef,
  rowId,
  children,
}: {
  rowId: string;
  icon?: string;
  onEditRecord?: (rowId: string) => void;
  getContainerRef?: () => React.RefObject<HTMLDivElement>;
  children?: React.ReactNode;
}) {
  const cellRef = useRef<HTMLDivElement>(null);

  const containerRef = getContainerRef?.();
  const { hoverRowId } = useGridTableHoverState(containerRef);

  const showExpandIcon = useMemo(() => {
    return hoverRowId === rowId;
  }, [hoverRowId, rowId]);

  return (
    <div ref={cellRef} className={'relative flex w-full items-center'}>
      {icon && <div className={'ml-2 mr-1'}>{icon}</div>}
      {children}
      <Suspense>
        {showExpandIcon && (
          <div
            style={{
              transform: 'translateY(-50%) translateZ(0)',
            }}
            className={`absolute right-0 top-1/2 z-10 mr-4 flex items-center justify-center`}
          >
            <IconButton onClick={() => onEditRecord?.(rowId)} className={'h-6 w-6 text-sm'}>
              <OpenIcon />
            </IconButton>
          </div>
        )}
      </Suspense>
    </div>
  );
}

export default PrimaryCell;
