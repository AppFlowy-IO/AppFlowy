import {
  DragEventHandler,
  RefObject,
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  useState,
} from 'react';
import { proxy, useSnapshot } from 'valtio';

export function isRef<T = unknown>(obj: unknown): obj is RefObject<T> {
  return obj !== null && typeof obj === 'object'
    && Object.prototype.hasOwnProperty.call(obj, 'current');
}

export interface DragItem<T = Record<string, unknown>> {
  type: string;
  data: T;
}

export interface DndContextDescriptor {
  dragging?: DragItem,
}

const defaultDndContext: DndContextDescriptor = proxy({
  dragging: undefined,
});

export const DndContext = createContext<DndContextDescriptor>(defaultDndContext);

export interface UseDraggableOptions {
  type: string;
  effectAllowed?: DataTransfer['effectAllowed'];
  data?: Record<string, any>;
  disabled?: boolean;
  onDragStart?: DragEventHandler;
  onDragEnd?: DragEventHandler;
}

export const useDraggable = ({
  type,
  effectAllowed = 'copyMove',
  data,
  disabled,
  onDragStart: handleDragStart,
  onDragEnd: handleDragEnd,
}: UseDraggableOptions) => {
  const context = useContext(DndContext);
  const typeRef = useRef(type);
  const dataRef = useRef(data);
  const previewRef = useRef<Element | null>(null);
  const [ isDragging, setIsDragging ] = useState(false);

  typeRef.current = type;
  dataRef.current = data;

  const setPreviewRef = useCallback((element: null | Element | RefObject<Element>) => {
    if (isRef(element)) {
      previewRef.current = element.current;
    } else {
      previewRef.current = element;
    }
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

    handleDragStart?.(event);
  }, [ context, effectAllowed, handleDragStart ]);

  const onDragEnd = useCallback<DragEventHandler>((event) => {
    setIsDragging(false);
    context.dragging = undefined;
    handleDragEnd?.(event);
  }, [ context, handleDragEnd ]);

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

interface UseDroppableOptions {
  accept: string;
  dropEffect?: DataTransfer['dropEffect'];
  disabled?: boolean;
  onDragOver?: DragEventHandler,
  onDrop?: (data: DragItem) => void;
}

export const useDroppable = ({
  accept,
  dropEffect = 'move',
  disabled,
  onDragOver: handleDragOver,
  onDrop: handleDrop,
}: UseDroppableOptions) => {
  const context = useContext(DndContext);
  const snapshot = useSnapshot(context);

  const [ dragOver, setDragOver ] = useState(false);
  const canDrop = useMemo(
    () => !disabled && snapshot.dragging?.type === accept,
    [ accept, disabled, snapshot.dragging?.type ],
  );
  const isOver = useMemo(()=> canDrop && dragOver, [ canDrop, dragOver ]);

  const onDragEnter = useCallback<DragEventHandler>((event) => {
    if (!canDrop) {
      return;
    }

    event.preventDefault();
    event.dataTransfer.dropEffect = dropEffect;

    setDragOver(true);
  }, [ canDrop, dropEffect ]);

  const onDragOver = useCallback<DragEventHandler>((event) => {
    if (!canDrop) {
      return;
    }

    event.preventDefault();
    event.dataTransfer.dropEffect = dropEffect;

    setDragOver(true);
    handleDragOver?.(event);
  }, [ canDrop, dropEffect, handleDragOver ]);

  const onDragLeave = useCallback(() => {
    if (!canDrop) {
      return;
    }

    setDragOver(false);
  }, [ canDrop ]);

  const onDrop = useCallback(() => {
    if (!canDrop) {
      return;
    }

    const { dragging } = context;

    if (!dragging) {
      return;
    }

    setDragOver(false);
    handleDrop?.(dragging);
  }, [ canDrop, handleDrop, context ]);

  const listeners = useMemo(() => ({
    onDragEnter,
    onDragOver,
    onDragLeave,
    onDrop,
  }), [ onDragEnter, onDragOver, onDragLeave, onDrop ]);

  return {
    isOver,
    canDrop,
    listeners,
  };
};
