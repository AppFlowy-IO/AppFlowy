import React, { useCallback, useEffect, useRef } from 'react';
import { blockDraggableActions, DraggableContext, DragInsertType } from '$app_reducers/block-draggable/slice';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { collisionNode, getDragDropContext, scrollIntoViewIfNeeded } from '$app/utils/draggable';
import { onDragEndThunk } from '$app_reducers/block-draggable/async_actions';
import { getBlock } from '$app/components/document/_shared/SubscribeNode.hooks';
import { blockConfig } from '$app/constants/document/config';

function BlockDragDropContext({ children }: { children: React.ReactNode }) {
  const shadowRef = useRef<HTMLDivElement>(null);
  const dispatch = useAppDispatch();
  const { dragging, draggingId, dragShadowVisible, draggingPosition } = useAppSelector((state) => state.blockDraggable);

  const registerDraggableEvents = useCallback(
    (id: string) => {
      const onDrag = (event: MouseEvent) => {
        const data = collisionNode(event, id);

        let dropContext: DraggableContext | undefined;
        const dropId = data?.id;
        let insertType = data?.insertType;

        if (dropId) {
          const context = getDragDropContext(dropId);
          const contextId = context?.contextId;
          const container = context?.container;

          if (container) {
            dropContext = {
              type: context.type,
              contextId: context.contextId,
            };

            scrollIntoViewIfNeeded(event, container as HTMLDivElement);
          }

          if (contextId) {
            const block = getBlock(contextId, dropId);

            if (block) {
              const config = blockConfig[block.type];

              if (!config.canAddChild && insertType === DragInsertType.CHILD) {
                insertType = DragInsertType.AFTER;
              }
            }
          }
        }

        dispatch(
          blockDraggableActions.drag({
            draggingPosition: {
              x: event.clientX,
              y: event.clientY,
            },
            insertType,
            dropId,
            dropContext,
          })
        );
      };

      const unlisten = () => {
        document.removeEventListener('mousemove', onDrag);
        document.removeEventListener('mouseup', onDragEnd);
      };

      const onDragEnd = () => {
        dispatch(onDragEndThunk());
        unlisten();
      };

      document.addEventListener('mousemove', onDrag);
      document.addEventListener('mouseup', onDragEnd);
      return unlisten;
    },
    [dispatch]
  );

  useEffect(() => {
    if (!dragging || !draggingId) return;
    return registerDraggableEvents(draggingId);
  }, [dragging, draggingId, registerDraggableEvents]);

  useEffect(() => {
    if (!shadowRef.current) return;
    if (!dragShadowVisible) {
      shadowRef.current.innerHTML = '';
      return;
    }

    const shadow = shadowRef.current;

    const draggingNode = document.querySelector(`[data-draggable-id="${draggingId}"]`);

    if (!draggingNode) return;
    const nodeWidth = draggingNode.clientWidth;
    const nodeHeight = draggingNode.clientHeight;
    const clone = draggingNode.cloneNode(true);

    shadow.style.width = `${nodeWidth}px`;
    shadow.style.height = `${nodeHeight}px`;
    shadow.appendChild(clone);
  }, [dragShadowVisible, draggingId]);

  return (
    <>
      {children}
      <div
        ref={shadowRef}
        style={{
          position: 'fixed',
          top: draggingPosition?.y,
          left: draggingPosition?.x,
          pointerEvents: 'none',
          opacity: dragShadowVisible ? 1 : 0,
          zIndex: 1000,
        }}
      />
    </>
  );
}

export default BlockDragDropContext;
