import React, { HTMLAttributes, useEffect } from 'react';
import { useDraggableState } from '$app/components/_shared/BlockDraggable/BlockDraggable.hooks';
import { BlockDraggableType } from '$app_reducers/block-draggable/slice';

function BlockDraggable(
  {
    id,
    type,
    children,
    getAnchorEl,
    className,
    ...props
  }: {
    id: string;
    type: BlockDraggableType;
    children: React.ReactNode;
    getAnchorEl?: () => HTMLElement | null;
  } & HTMLAttributes<HTMLDivElement>,
  ref: React.Ref<HTMLDivElement>
) {
  const { onDragStart, beforeDropping, afterDropping, childDropping, isDragging } = useDraggableState(id, type);

  const commonCls = 'pointer-events-none absolute z-10 w-[100%] bg-fill-hover transition-all duration-200';

  useEffect(() => {
    if (!getAnchorEl) return;
    const el = getAnchorEl();

    if (!el) return;
    el.addEventListener('mousedown', onDragStart);
    return () => {
      el.removeEventListener('mousedown', onDragStart);
    };
  }, [getAnchorEl, onDragStart]);
  return (
    <>
      <div
        ref={ref}
        data-draggable-id={id}
        data-draggable-type={type}
        onMouseDown={getAnchorEl ? undefined : onDragStart}
        className={`relative ${className || ''}`}
        style={{
          opacity: isDragging ? 0.7 : 1,
        }}
        {...props}
      >
        {
          <div
            style={{
              visibility: beforeDropping ? 'visible' : 'hidden',
            }}
            className={`${commonCls} left-0 top-[-2px] h-[4px]`}
          />
        }

        {children}
        {
          <div
            style={{
              visibility: childDropping ? 'visible' : 'hidden',
            }}
            className={`${commonCls} left-0 top-0 h-[100%] opacity-[0.3]`}
          />
        }
        {
          <div
            style={{
              visibility: afterDropping ? 'visible' : 'hidden',
            }}
            className={`${commonCls} bottom-[-2px] left-0 h-[4px]`}
          />
        }
      </div>
    </>
  );
}

export default React.memo(React.forwardRef(BlockDraggable));
