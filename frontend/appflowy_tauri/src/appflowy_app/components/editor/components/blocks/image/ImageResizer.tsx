import React, { useCallback, useRef } from 'react';

function ImageResizer({
  minWidth,
  width,
  onWidthChange,
}: {
  minWidth: number;
  width: number;
  onWidthChange: (newWidth: number) => void;
}) {
  const originalWidth = useRef(width);
  const startX = useRef(0);

  const onResize = useCallback(
    (e: MouseEvent) => {
      e.preventDefault();
      const diff = e.clientX - startX.current;
      const newWidth = originalWidth.current + diff;

      if (newWidth < minWidth) {
        return;
      }

      onWidthChange(newWidth);
    },
    [minWidth, onWidthChange]
  );

  const onResizeEnd = useCallback(() => {
    document.removeEventListener('mousemove', onResize);
    document.removeEventListener('mouseup', onResizeEnd);
  }, [onResize]);

  const onResizeStart = useCallback(
    (e: React.MouseEvent) => {
      startX.current = e.clientX;
      originalWidth.current = width;
      document.addEventListener('mousemove', onResize);
      document.addEventListener('mouseup', onResizeEnd);
    },
    [onResize, onResizeEnd, width]
  );

  return (
    <div
      onMouseDown={onResizeStart}
      style={{
        right: '2px',
      }}
      className={'image-resizer'}
    >
      <div className={'resize-handle'} />
    </div>
  );
}

export default ImageResizer;
