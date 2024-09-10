import React, { useState, useCallback, useEffect } from 'react';

const Resizer = ({
  minWidth = Math.min(268, window.innerWidth / 4),
  maxWidth = Math.max(268, window.innerWidth / 2),
  onResize,
}: {
  drawerWidth: number;
  minWidth?: number;
  maxWidth?: number;
  onResize?: (width: number) => void;
}) => {
  const [isResizing, setIsResizing] = useState(false);

  const startResizing = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
    e.preventDefault();
    setIsResizing(true);
  }, []);

  const stopResizing = useCallback(() => {
    setIsResizing(false);
  }, []);

  const resize = useCallback(
    (mouseMoveEvent: MouseEvent) => {
      if (isResizing) {
        mouseMoveEvent.stopPropagation();
        mouseMoveEvent.preventDefault();
        const newWidth = mouseMoveEvent.clientX;

        if (newWidth >= minWidth && newWidth <= maxWidth && newWidth + 768 < window.innerWidth) {
          onResize?.(newWidth);
        }
      }
    },
    [isResizing, minWidth, maxWidth, onResize],
  );

  useEffect(() => {
    window.addEventListener('mousemove', resize);
    window.addEventListener('mouseup', stopResizing);
    return () => {
      window.removeEventListener('mousemove', resize);
      window.removeEventListener('mouseup', stopResizing);
    };
  }, [resize, stopResizing]);

  return (
    <div
      className="absolute top-0 h-full w-2 border-r-4 border-transparent hover:border-content-blue-300 cursor-col-resize"
      style={{ right: 0, zIndex: 100, borderColor: isResizing ? 'var(--content-blue-300)' : undefined }}
      onMouseDown={startResizing}
    />
  );
};

export default Resizer;