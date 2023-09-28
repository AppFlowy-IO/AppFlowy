import {
  DragEventHandler,
  useCallback,
  useContext,
  useMemo,
  useRef,
  useState,
} from 'react';
import { DndContext } from './dnd.context';
import { autoScrollOnEdge, EdgeGap, getScrollParent, ScrollDirection } from './utils';

export interface UseDraggableOptions {
  type: string;
  effectAllowed?: DataTransfer['effectAllowed'];
  data?: Record<string, any>;
  disabled?: boolean;
  scrollOnEdge?: {
    direction?: ScrollDirection;
    edgeGap?: number | Partial<EdgeGap>;
  };
}

export const useDraggable = ({
  type,
  effectAllowed = 'copyMove',
  data,
  disabled,
  scrollOnEdge,
}: UseDraggableOptions) => {
  const scrollDirection = scrollOnEdge?.direction;
  const edgeGap = scrollOnEdge?.edgeGap;

  const context = useContext(DndContext);
  const typeRef = useRef(type);
  const dataRef = useRef(data);
  const previewRef = useRef<Element | null>(null);
  const [ isDragging, setIsDragging ] = useState(false);

  typeRef.current = type;
  dataRef.current = data;

  const setPreviewRef = useCallback((previewElement: null | Element) => {
    previewRef.current = previewElement;
  }, []);

  const attributes = useMemo(() => {
    if (disabled) {
      return {};
    }

    return {
      draggable: true,
    };
  }, [disabled]);

  const onDragStart = useCallback<DragEventHandler>((event) => {
    setIsDragging(true);
    context.dragging = {
      type: typeRef.current,
      data: dataRef.current ?? {},
    };

    const { dataTransfer } = event;
    const previewNode = previewRef.current;

    dataTransfer.effectAllowed = effectAllowed;

    if (previewNode) {
      const { clientX, clientY } = event;
      const rect = previewNode.getBoundingClientRect();

      dataTransfer.setDragImage(previewNode, clientX - rect.x, clientY - rect.y);
    }

    if (scrollDirection === undefined) {
      return;
    }

    const scrollParent: HTMLElement | null = getScrollParent(event.target as HTMLElement, scrollDirection);

    if (scrollParent) {
      autoScrollOnEdge({
        element: scrollParent,
        direction: scrollDirection,
        edgeGap,
      });
    }
  }, [ context, effectAllowed, scrollDirection, edgeGap ]);

  const onDragEnd = useCallback<DragEventHandler>(() => {
    setIsDragging(false);
    context.dragging = null;
  }, [ context ]);

  const listeners = useMemo(() => ({
    onDragStart,
    onDragEnd,
  }), [ onDragStart, onDragEnd]);

  return {
    isDragging,
    previewRef,
    attributes,
    listeners,
    setPreviewRef,
  };
};
