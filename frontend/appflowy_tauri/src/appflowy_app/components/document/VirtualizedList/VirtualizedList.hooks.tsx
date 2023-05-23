import { useVirtualizer } from '@tanstack/react-virtual';
import { useRef } from 'react';

const defaultSize = 30;

export function useVirtualizedList(count: number) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualize = useVirtualizer({
    count,
    getScrollElement: () => parentRef.current,
    overscan: 5,
    estimateSize: () => {
      return defaultSize;
    },
  });

  return {
    virtualize,
    parentRef,
  };
}
