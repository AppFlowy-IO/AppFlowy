import React, { Suspense, useEffect, useRef, useState } from 'react';
import { ReactComponent as OpenIcon } from '$app/assets/open.svg';
import { TextCell } from './TextCell';
import { Field, TextCell as TextCellType } from '../../application';
import { IconButton } from '@mui/material';

function PrimaryCell({
  cell,
  onEditRecord,
  icon,
  ...props
}: {
  field: Field;
  cell: TextCellType;
  icon?: string;
  placeholder?: string;
  onEditRecord?: (rowId: string) => void;
}) {
  const cellRef = useRef<HTMLDivElement>(null);
  const [showExpandIcon, setShowExpandIcon] = useState(false);

  useEffect(() => {
    const rowEl = document.querySelector(`[data-key="row:${cell.rowId}"]`);

    if (!rowEl) return;
    const onEnter = () => {
      setShowExpandIcon(true);
    };

    const onLeave = () => {
      setShowExpandIcon(false);
    };

    rowEl.addEventListener('mouseenter', onEnter);
    rowEl.addEventListener('mouseleave', onLeave);

    return () => {
      rowEl.removeEventListener('mouseenter', onEnter);
      rowEl.removeEventListener('mouseleave', onLeave);
    };
  }, [cell.rowId]);

  return (
    <div ref={cellRef} className={'relative flex h-full w-full items-center'}>
      {icon && <div className={'ml-2 mr-1'}>{icon}</div>}
      <TextCell {...props} cell={cell} />
      <Suspense>
        {showExpandIcon && (
          <div
            style={{
              transform: 'translateY(-50%) translateZ(0)',
            }}
            className={`absolute right-0 top-1/2 z-10 mr-4 flex items-center justify-center`}
          >
            <IconButton onClick={() => onEditRecord?.(cell.rowId)} className={'h-6 w-6 text-sm'}>
              <OpenIcon />
            </IconButton>
          </div>
        )}
      </Suspense>
    </div>
  );
}

export default PrimaryCell;
