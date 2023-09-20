import { MouseEventHandler, useCallback, useEffect, useMemo, useRef } from 'react';
import { interval } from '$app/utils/tool';

enum Direction {
  Top = 'top',
  Bottom = 'bottom',
  Left = 'left',
  Right = 'right',
}

const isReachEdge = (element: Element, direction: Direction) => {
  switch (direction) {
    case Direction.Left:
      return element.scrollLeft === 0;
    case Direction.Right:
      return element.scrollLeft + element.clientWidth === element.scrollWidth;
    case Direction.Top:
      return element.scrollTop === 0;
    case Direction.Bottom:
      return element.scrollTop + element.clientHeight === element.scrollHeight;
    default:
      return true;
  }
};

const scrollBy = (element: Element, direction: Direction, offset: number) => {
  let step = offset;
  let prop = direction;

  if (direction === Direction.Left || direction === Direction.Top) {
    step = -offset;
  } else if (direction === Direction.Right) {
    prop = Direction.Left;
  } else if (direction === Direction.Bottom) {
    prop = Direction.Top;
  }

  element.scrollBy({ [prop]: step });
};

const scrollElement = (element: Element, direction: Direction, offset: number) => {
  if (isReachEdge(element, direction)) {
    return;
  }

  scrollBy(element, direction, offset);
};

const calculateLeaveEdge = (
  { x: mouseX, y: mouseY }: { x: number; y: number },
  rect: DOMRect,
  gaps: EdgeGap,
  { horizontal, vertical }: { horizontal: boolean; vertical: boolean },
) => {
  if (horizontal) {
    if (mouseX - rect.left < gaps.left) {
      return Direction.Left;
    }

    if (rect.right - mouseX < gaps.right) {
      return Direction.Right;
    }
  }

  if (vertical) {
    if (mouseY - rect.top < gaps.top) {
      return Direction.Top;
    }

    if (rect.bottom - mouseY < gaps.bottom) {
      return Direction.Bottom;
    }
  }

  return undefined;
};

export interface EdgeGap {
  top: number;
  bottom: number;
  left: number;
  right: number;
}

export interface UseAutoScrollOnEdgeOptions {
  trigger?: 'mouse' | 'drag';
  horizontal?: boolean;
  vertical?: boolean;
  edgeGap?: number | Partial<EdgeGap>;
  disabled?: boolean
}

const defaultEdgeGap = 30;

/**
 * Generates listeners to be bound to the element where you want to trigger auto scroll when mouse move to the edge.
 *
 * @param {Object} options - The options for the function.
 * @param {string} [options.trigger] - Determine how to trigger the auto scroll, 'mouse' for mouse events, and 'drag' for drag events. Defaults to 'mouse'.
 * @param {boolean} [options.horizontal] - Whether the auto scroll is enabled horizontally. Defaults to false.
 * @param {boolean} [options.vertical] - Whether the auto scroll is enabled vertically. Defaults to false.
 * @param {number | { top: number, bottom: number, left: number, right: number }} [options.edgeGap] - The edge gap for the auto scroll. Defaults to 30.
 * @param {boolean} [options.disabled] - Whether the auto scroll is disabled. Defaults to false.
 *
 * @return {Object} The auto scroll event handlers.
 *
 * @example
 *
 * const Foo = () => {
 *   const [disabled, setDisabled] = useState(false);
 *
 *   const listeners = useAutoScrollOnEdge({
 *     vertical: true, // enable auto scroll on vertical.
 *     edgeGap: 30, // same to { top: 30, bottom: 30, left: 30, right: 30 }.
 *     disabled: disabled, // control the auto scroll whether enable or not.
 *   });
 *
 *   return (
 *     // the element where you want to trigger auto scroll
 *     <div className="scroll-container" {...listener}>
 *       {...}
 *     </div>
 *   );
 * };
 */
export const useAutoScrollOnEdge = ({
  trigger = 'mouse',
  horizontal = false,
  vertical = false,
  edgeGap = defaultEdgeGap,
  disabled,
}: UseAutoScrollOnEdgeOptions = {}) => {
  const gaps = useMemo<EdgeGap>(() => {
    if (typeof edgeGap === 'number') {
      return {
        top: edgeGap,
        bottom: edgeGap,
        left: edgeGap,
        right: edgeGap,
      };
    }

    return {
      top: defaultEdgeGap,
      bottom: defaultEdgeGap,
      left: defaultEdgeGap,
      right: defaultEdgeGap,
      ...edgeGap,
    };
  }, [edgeGap]);

  const leaveEdge = useRef<Direction>();

  const keepScroll = useRef(interval(scrollElement, 16));

  useEffect(() => {
    if (disabled) {
      keepScroll.current.cancel();
    }
  }, [disabled]);

  const onMouseMove = useCallback<MouseEventHandler>((event) => {
    const scrollParent = event.currentTarget;
    const rect = scrollParent.getBoundingClientRect();

    leaveEdge.current = calculateLeaveEdge(
      { x: event.clientX, y: event.clientY },
      rect,
      gaps,
      { horizontal, vertical },
    );

    if (leaveEdge.current) {
      keepScroll.current(scrollParent, leaveEdge.current, 20);
    } else {
      keepScroll.current.cancel();
    }
  }, [horizontal, vertical, gaps]);

  const onMouseLeave = useCallback<MouseEventHandler>((event) => {
    if (!leaveEdge.current) {
      return;
    }

    const scrollParent = event.currentTarget;

    keepScroll.current(scrollParent, leaveEdge.current, 40);
  }, []);

  if (disabled) {
    return {};
  }

  return trigger === 'drag'
    ? {
      onDragOver: onMouseMove,
      onDragLeave: onMouseLeave,
    }
    : {
      onMouseMove,
      onMouseLeave,
    };
};
