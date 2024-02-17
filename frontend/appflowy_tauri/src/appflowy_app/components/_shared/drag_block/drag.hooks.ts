import React from 'react';

interface Props {
  dragId?: string;
  onEnd?: (result: { dragId: string; position: 'before' | 'after' | 'inside' }) => void;
}

function calcPosition(targetRect: DOMRect, clientY: number) {
  const top = targetRect.top + targetRect.height / 3;
  const bottom = targetRect.bottom - targetRect.height / 3;

  if (clientY < top) return 'before';
  if (clientY > bottom) return 'after';
  return 'inside';
}

export function useDrag(props: Props) {
  const { dragId, onEnd } = props;
  const [isDraggingOver, setIsDraggingOver] = React.useState(false);
  const [isDragging, setIsDragging] = React.useState(false);
  const [dropPosition, setDropPosition] = React.useState<'before' | 'after' | 'inside'>();
  const onDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.stopPropagation();
    setIsDraggingOver(false);
    setIsDragging(false);
    setDropPosition(undefined);
    const currentTarget = e.currentTarget;

    if (currentTarget.parentElement?.closest(`[data-drop-enabled="false"]`)) return;
    if (currentTarget.closest(`[data-dragging="true"]`)) return;
    const dragId = e.dataTransfer.getData('dragId');
    const targetRect = currentTarget.getBoundingClientRect();
    const { clientY } = e;

    const position = calcPosition(targetRect, clientY);

    onEnd && onEnd({ dragId, position });
  };

  const onDragOver = (e: React.DragEvent<HTMLDivElement>) => {
    e.stopPropagation();
    e.preventDefault();
    if (isDragging) return;
    const currentTarget = e.currentTarget;

    if (currentTarget.parentElement?.closest(`[data-drop-enabled="false"]`)) return;
    if (currentTarget.closest(`[data-dragging="true"]`)) return;
    setIsDraggingOver(true);
    const targetRect = currentTarget.getBoundingClientRect();
    const { clientY } = e;
    const position = calcPosition(targetRect, clientY);

    setDropPosition(position);
  };

  const onDragLeave = (e: React.DragEvent<HTMLDivElement>) => {
    e.stopPropagation();
    setIsDraggingOver(false);
    setDropPosition(undefined);
  };

  const onDragStart = (e: React.DragEvent<HTMLDivElement>) => {
    if (!dragId) return;
    e.stopPropagation();
    e.dataTransfer.setData('dragId', dragId);
    e.dataTransfer.effectAllowed = 'move';
    setIsDragging(true);
  };

  const onDragEnd = (e: React.DragEvent<HTMLDivElement>) => {
    e.stopPropagation();
    setIsDragging(false);
    setIsDraggingOver(false);
    setDropPosition(undefined);
  };

  return {
    onDrop,
    onDragOver,
    onDragLeave,
    onDragStart,
    isDraggingOver,
    isDragging,
    onDragEnd,
    dropPosition,
  };
}
