import { DragEventHandler, useContext, useState, useMemo, useCallback } from 'react';
import { useSnapshot } from 'valtio';
import { DragItem, DndContext } from './dnd.context';

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
  const dndContext = useContext(DndContext);
  const dndSnapshot = useSnapshot(dndContext);

  const [ dragOver, setDragOver ] = useState(false);
  const canDrop = useMemo(
    () => !disabled && dndSnapshot.dragging?.type === accept,
    [ disabled, accept, dndSnapshot.dragging?.type ],
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

    const dragging = dndSnapshot.dragging;

    if (!dragging) {
      return;
    }

    setDragOver(false);
    handleDrop?.(dragging);
  }, [ canDrop, dndSnapshot.dragging, handleDrop ]);

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
