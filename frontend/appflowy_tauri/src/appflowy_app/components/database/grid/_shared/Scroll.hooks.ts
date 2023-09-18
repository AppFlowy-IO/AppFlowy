import { MouseEventHandler, useCallback, useMemo } from 'react';

export interface UseAutoScrollOptions {
  horizontal?: boolean;
  vertical?: boolean;
  gap?: number | [number, number];
  disabled?: boolean
}

export const useAutoScroll = ({
  horizontal,
  vertical,
  gap = 30,
  disabled,
}: UseAutoScrollOptions = {}) => {

  const gaps = useMemo(() => Array.isArray(gap) ? gap : [gap, gap], [gap]);

  const onMouseMove = useCallback<MouseEventHandler>((event) => {
    if (disabled) {
      return;
    }

    const scrollParent = event.currentTarget;
    const rect = scrollParent.getBoundingClientRect();
    const { clientX, clientY } = event;

    if (vertical) {
      const topGap = clientY - rect.top;

      if (topGap < gaps[0] ) {
        console.log('move into top edge');
        return;
      }

      const bottomGap = rect.bottom - clientY;

      if (bottomGap < gaps[0]) {
        console.log('move into right edge');
        return;
      }
    }

    if (horizontal) {
      const leftGap = clientX - rect.left;

      if (leftGap < gaps[1] ) {
        console.log('move into left edge');
        return;
      }

      const rightGap = rect.right - clientX;

      if (rightGap < gaps[1]) {
        console.log('move into right edge');
        return;
      }
    }

  }, [horizontal, vertical, disabled, gaps]);

  return {
    onMouseMove,
  };
};
