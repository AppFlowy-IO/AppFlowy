import { useVirtualizer } from '@tanstack/react-virtual';
import { useRef } from 'react';

const defaultSize = 60;

export function useVirtualizerList(count: number) {
  const parentRef = useRef<HTMLDivElement>(null);

  const rowVirtualizer = useVirtualizer({
    count,
    getScrollElement: () => parentRef.current,
    estimateSize: () => {
      return defaultSize;
    },
  });

  return {
    rowVirtualizer,
    parentRef,
  };
}
