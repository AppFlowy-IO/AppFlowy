import React, { useCallback, useRef, useState } from 'react';
import { Field, fieldService } from '$app/application/database';
import { useViewId } from '$app/hooks';

interface GridResizerProps {
  field: Field;
  onWidthChange?: (width: number) => void;
}

const minWidth = 150;

export function GridResizer({ field, onWidthChange }: GridResizerProps) {
  const viewId = useViewId();
  const fieldId = field.id;
  const width = field.width || 0;
  const [isResizing, setIsResizing] = useState(false);
  const [hover, setHover] = useState(false);
  const startX = useRef(0);
  const newWidthRef = useRef(width);
  const onResize = useCallback(
    (e: MouseEvent) => {
      const diff = e.clientX - startX.current;
      const newWidth = width + diff;

      if (newWidth < minWidth) {
        return;
      }

      newWidthRef.current = newWidth;
      onWidthChange?.(newWidth);
    },
    [width, onWidthChange]
  );

  const onResizeEnd = useCallback(() => {
    setIsResizing(false);

    void fieldService.updateFieldSetting(viewId, fieldId, {
      width: newWidthRef.current,
    });
    document.removeEventListener('mousemove', onResize);
    document.removeEventListener('mouseup', onResizeEnd);
  }, [fieldId, onResize, viewId]);

  const onResizeStart = useCallback(
    (e: React.MouseEvent) => {
      e.stopPropagation();
      e.preventDefault();
      startX.current = e.clientX;
      setIsResizing(true);
      document.addEventListener('mousemove', onResize);
      document.addEventListener('mouseup', onResizeEnd);
    },
    [onResize, onResizeEnd]
  );

  return (
    <div
      onMouseDown={onResizeStart}
      onClick={(e) => {
        e.stopPropagation();
      }}
      onMouseEnter={() => {
        setHover(true);
      }}
      onMouseLeave={() => {
        setHover(false);
      }}
      style={{
        right: `-3px`,
      }}
      className={'absolute top-0 z-10 h-full cursor-col-resize'}
    >
      <div
        className={'h-full w-[6px] select-none bg-transparent'}
        style={{
          backgroundColor: hover || isResizing ? 'var(--content-on-fill-hover)' : 'transparent',
        }}
      ></div>
    </div>
  );
}

export default GridResizer;
