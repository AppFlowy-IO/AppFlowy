import { useVirtualizer } from '@tanstack/react-virtual';
import { useRef } from 'react';

const defaultSize = 60;

export function useVirtualizedList(count: number) {
  const parentRef = useRef<HTMLDivElement>(null);

  const Virtualize = useVirtualizer({
    count,
    getScrollElement: () => parentRef.current,
    estimateSize: () => {
      return defaultSize;
    },
  });

  return {
    Virtualize: Virtualize,
    parentRef,
  };
}
