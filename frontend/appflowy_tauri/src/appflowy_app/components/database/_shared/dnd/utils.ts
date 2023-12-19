import { interval } from '$app/utils/tool';

export enum Edge {
  Top = 'top',
  Bottom = 'bottom',
  Left = 'left',
  Right = 'right',
}

export enum ScrollDirection {
  Horizontal = 'horizontal',
  Vertical = 'vertical',
}

export interface EdgeGap {
  top: number;
  bottom: number;
  left: number;
  right: number;
}

export const isReachEdge = (element: Element, edge: Edge) => {
  switch (edge) {
    case Edge.Left:
      return element.scrollLeft === 0;
    case Edge.Right:
      return element.scrollLeft + element.clientWidth === element.scrollWidth;
    case Edge.Top:
      return element.scrollTop === 0;
    case Edge.Bottom:
      return element.scrollTop + element.clientHeight === element.scrollHeight;
    default:
      return true;
  }
};

export const scrollBy = (element: Element, edge: Edge, offset: number) => {
  let step = offset;
  let prop = edge;

  if (edge === Edge.Left || edge === Edge.Top) {
    step = -offset;
  } else if (edge === Edge.Right) {
    prop = Edge.Left;
  } else if (edge === Edge.Bottom) {
    prop = Edge.Top;
  }

  element.scrollBy({ [prop]: step });
};

export const scrollElement = (element: Element, edge: Edge, offset: number) => {
  if (isReachEdge(element, edge)) {
    return;
  }

  scrollBy(element, edge, offset);
};

export const calculateLeaveEdge = (
  { x: mouseX, y: mouseY }: { x: number; y: number },
  rect: DOMRect,
  gaps: EdgeGap,
  direction: ScrollDirection
) => {
  if (direction === ScrollDirection.Horizontal) {
    if (mouseX - rect.left < gaps.left) {
      return Edge.Left;
    }

    if (rect.right - mouseX < gaps.right) {
      return Edge.Right;
    }
  }

  if (direction === ScrollDirection.Vertical) {
    if (mouseY - rect.top < gaps.top) {
      return Edge.Top;
    }

    if (rect.bottom - mouseY < gaps.bottom) {
      return Edge.Bottom;
    }
  }

  return null;
};

export const getScrollParent = (element: HTMLElement | null, direction: ScrollDirection): HTMLElement | null => {
  if (element === null) {
    return null;
  }

  if (direction === ScrollDirection.Horizontal && element.scrollWidth > element.clientWidth) {
    return element;
  }

  if (direction === ScrollDirection.Vertical && element.scrollHeight > element.clientHeight) {
    return element;
  }

  return getScrollParent(element.parentElement, direction);
};

export interface AutoScrollOnEdgeOptions {
  element: HTMLElement;
  direction: ScrollDirection;
  edgeGap?: number | Partial<EdgeGap>;
  step?: number;
}

const defaultEdgeGap = 30;

export const autoScrollOnEdge = ({ element, direction, edgeGap, step = 8 }: AutoScrollOnEdgeOptions) => {
  const gaps =
    typeof edgeGap === 'number'
      ? {
          top: edgeGap,
          bottom: edgeGap,
          left: edgeGap,
          right: edgeGap,
        }
      : {
          top: defaultEdgeGap,
          bottom: defaultEdgeGap,
          left: defaultEdgeGap,
          right: defaultEdgeGap,
          ...edgeGap,
        };

  const keepScroll = interval(scrollElement, 8);

  let leaveEdge: Edge | null = null;

  const onDragOver = (event: DragEvent) => {
    const rect = element.getBoundingClientRect();

    leaveEdge = calculateLeaveEdge({ x: event.clientX, y: event.clientY }, rect, gaps, direction);

    if (leaveEdge) {
      keepScroll(element, leaveEdge, step);
    } else {
      keepScroll.cancel();
    }
  };

  const onDragLeave = () => {
    if (!leaveEdge) {
      return;
    }

    keepScroll(element, leaveEdge, step * 2);
  };

  const cleanup = () => {
    keepScroll.cancel();

    element.removeEventListener('dragover', onDragOver);
    element.removeEventListener('dragleave', onDragLeave);

    document.removeEventListener('dragend', cleanup);
  };

  element.addEventListener('dragover', onDragOver);
  element.addEventListener('dragleave', onDragLeave);

  document.addEventListener('dragend', cleanup);

  return cleanup;
};
