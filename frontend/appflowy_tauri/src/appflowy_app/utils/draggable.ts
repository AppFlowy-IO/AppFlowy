import { BlockDraggableType, DragInsertType } from '$app_reducers/block-draggable/slice';
import { findParent } from '$app/utils/document/node';
import { nanoid } from 'nanoid';
import { getBlock } from '$app/components/document/_shared/SubscribeNode.hooks';
import { blockConfig } from '$app/constants/document/config';

export function getDraggableIdByPoint(target: HTMLElement | null) {
  let node = target;

  while (node) {
    const id = node.getAttribute('data-draggable-id');

    if (id) {
      return id;
    }

    node = node.parentElement;
  }

  return null;
}

export function getDraggableNode(id: string) {
  return document.querySelector(`[data-draggable-id="${id}"]`);
}

export function getDragDropContext(id: string) {
  const node = getDraggableNode(id);

  if (!node) return;
  const type = node.getAttribute('data-draggable-type') as BlockDraggableType;
  const container = node.closest('[id^=appflowy-scroller]');

  if (!container) return;
  const containerId = container.id;
  const contextId = containerId.split('_')[1];

  return {
    contextId,
    container,
    type,
  };
}

export function collisionNode(event: MouseEvent, draggingId: string) {
  event.stopPropagation();
  const { clientY, target, clientX } = event;

  if (!target) return;
  let id = getDraggableIdByPoint(target as HTMLElement);

  if (!id) return;

  if (id === draggingId) return;

  const parentIsDraggingId = (target as HTMLElement).closest(`[data-draggable-id="${draggingId}"]`);

  if (parentIsDraggingId) return;

  const node = getDraggableNode(id);

  if (!node) return;
  const { top, bottom, left } = node.getBoundingClientRect();

  let parent = node.parentElement;
  let nodeLeft = left;

  while (parent && clientX < nodeLeft) {
    const parentNode = findParent(parent, '[data-draggable-id]');

    if (!parentNode) break;
    const parentId = parentNode.getAttribute('data-draggable-id');

    id = parentId || id;
    nodeLeft = parentNode.getBoundingClientRect().left;
    parent = parentNode.parentElement;
  }

  let insertType = DragInsertType.CHILD;

  if (clientY - top < 4) {
    insertType = DragInsertType.BEFORE;
  }

  if (clientY > bottom - 4) {
    insertType = DragInsertType.AFTER;
  }

  return {
    id,
    insertType,
  };
}

const scrollThreshold = 20;

export function scrollIntoViewIfNeeded(e: MouseEvent, container: HTMLDivElement) {
  const { top, bottom } = container.getBoundingClientRect();

  let delta = 0;

  if (e.clientY + scrollThreshold >= bottom) {
    delta = e.clientY + scrollThreshold - bottom;
  } else if (e.clientY - scrollThreshold <= top) {
    delta = e.clientY - scrollThreshold - top;
  }

  container.scrollBy(0, delta);
}

export function generateDragContextId() {
  return nanoid(10);
}
