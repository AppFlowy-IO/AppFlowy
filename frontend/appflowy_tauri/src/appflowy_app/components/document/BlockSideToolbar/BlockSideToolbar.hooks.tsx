import { BlockType, HeadingBlockData } from '@/appflowy_app/interfaces/document';
import { useAppSelector } from '@/appflowy_app/stores/store';
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { PopoverOrigin } from '@mui/material/Popover/Popover';
import { getBlock } from '$app/components/document/_shared/SubscribeNode.hooks';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { RANGE_NAME, RECT_RANGE_NAME } from '$app/constants/document/name';
import { getNode } from '$app/utils/document/node';
import { get } from '$app/utils/tool';

const headingBlockTopOffset: Record<number, string> = {
  1: '0.4rem',
  2: '0.35rem',
  3: '0.15rem',
};

export function useBlockSideToolbar(id: string) {
  const { docId } = useSubscribeDocument();

  const isDragging = useAppSelector((state) => {
    return (
      get(state, [RECT_RANGE_NAME, docId, 'isDragging'], false) ||
      get(state, [RANGE_NAME, docId, 'isDragging'], false) ||
      get(state, ['blockDraggable', 'dragging'], false)
    );
  });
  const ref = useRef<HTMLDivElement | null>(null);
  const [opacity, setOpacity] = useState(0);

  const topOffset = useMemo(() => {
    const block = getBlock(docId, id);

    if (!block) return 0;
    if (block.type === BlockType.HeadingBlock) {
      return headingBlockTopOffset[(block.data as HeadingBlockData).level];
    }

    if (block.type === BlockType.DividerBlock) {
      return -6;
    }

    if (block.type === BlockType.GridBlock) {
      return 16;
    }

    return 0;
  }, [docId, id]);

  const onMouseMove = useCallback(
    (e: Event) => {
      if (isDragging) {
        setOpacity(0);
        return;
      }

      const target = (e.target as HTMLElement).closest('[data-block-id]');

      if (!target) return;
      const targetId = target.getAttribute('data-block-id');

      if (targetId !== id) {
        setOpacity(0);
        return;
      }

      setOpacity(1);
    },
    [id, isDragging]
  );

  const onMouseLeave = useCallback(() => {
    setOpacity(0);
  }, []);

  useEffect(() => {
    const node = getNode(id);

    if (!node) return;
    node.addEventListener('mousemove', onMouseMove);
    node.addEventListener('mouseleave', onMouseLeave);
    return () => {
      node.removeEventListener('mousemove', onMouseMove);
      node.removeEventListener('mouseleave', onMouseLeave);
    };
  }, [id, onMouseMove, onMouseLeave]);

  return {
    ref,
    opacity,
    topOffset,
  };
}

const transformOrigin: PopoverOrigin = {
  vertical: 'bottom',
  horizontal: 'left',
};

export function usePopover() {
  const [anchorPosition, setAnchorPosition] = React.useState<{
    top: number;
    left: number;
  }>();

  const onClose = useCallback(() => {
    setAnchorPosition(undefined);
  }, []);

  const handleOpen = useCallback((e: React.MouseEvent<HTMLButtonElement>) => {
    e.preventDefault();
    const rect = e.currentTarget.getBoundingClientRect();

    setAnchorPosition({
      top: rect.top + rect.height,
      left: rect.left + rect.width,
    });
  }, []);

  const open = Boolean(anchorPosition);

  const onMouseDown = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
    e.stopPropagation();
  }, []);

  return {
    anchorPosition,
    onClose,
    open,
    handleOpen,
    anchorReference: 'anchorPosition' as const,
    transformOrigin,
    onMouseDown,
    disableRestoreFocus: true,
    disableAutoFocus: true,
    disableEnforceFocus: true,
  };
}
