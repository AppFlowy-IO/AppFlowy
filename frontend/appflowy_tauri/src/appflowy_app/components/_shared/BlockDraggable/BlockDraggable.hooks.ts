import React, { useCallback, useMemo } from 'react';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { blockDraggableActions, BlockDraggableType, DragInsertType } from '$app_reducers/block-draggable/slice';
import { getDragDropContext } from '$app/utils/draggable';

export function useDraggableState(id: string, type: BlockDraggableType) {
  const dispatch = useAppDispatch();
  const { dropState, isDragging } = useAppSelector((state) => {
    const draggableState = state.blockDraggable;
    const isDragging = draggableState.dragging && draggableState.draggingId === id;

    if (draggableState.dropId === id) {
      return {
        dropState: {
          dropId: draggableState.dropId,
          insertType: draggableState.insertType,
        },
        isDragging,
      };
    }

    return {
      dropState: null,
      isDragging,
    };
  });

  const onDragStart = useCallback(
    (event: React.MouseEvent | MouseEvent) => {
      if (event.button !== 0) return;

      event.preventDefault();
      event.stopPropagation();
      const { clientY: y, clientX: x } = event;

      const context = getDragDropContext(id);

      if (!context) return;

      dispatch(
        blockDraggableActions.startDrag({
          startDraggingPosition: {
            x,
            y,
          },
          draggingId: id,
          draggingContext: {
            type,
            contextId: context.contextId,
          },
        })
      );
    },
    [dispatch, id, type]
  );

  const beforeDropping = useMemo(() => {
    if (!dropState) return false;
    return dropState.insertType === DragInsertType.BEFORE;
  }, [dropState]);

  const afterDropping = useMemo(() => {
    if (!dropState) return false;
    return dropState.insertType === DragInsertType.AFTER;
  }, [dropState]);

  const childDropping = useMemo(() => {
    if (!dropState) return false;
    return dropState.insertType === DragInsertType.CHILD;
  }, [dropState]);

  return {
    onDragStart,
    beforeDropping,
    afterDropping,
    childDropping,
    isDragging,
  };
}
