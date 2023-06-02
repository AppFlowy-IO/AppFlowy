import { BlockType, HeadingBlockData } from '@/appflowy_app/interfaces/document';
import { useAppDispatch } from '@/appflowy_app/stores/store';
import React, { useCallback, useEffect, useRef, useState } from 'react';
import { PopoverOrigin } from '@mui/material/Popover/Popover';
import { getBlock } from '$app/components/document/_shared/SubscribeNode.hooks';

const headingBlockTopOffset: Record<number, number> = {
  1: 7,
  2: 5,
  3: 4,
};
export function useBlockSideToolbar({ container }: { container: HTMLDivElement }) {
  const [nodeId, setHoverNodeId] = useState<string | null>(null);
  const ref = useRef<HTMLDivElement | null>(null);
  const dispatch = useAppDispatch();
  const [style, setStyle] = useState<React.CSSProperties>({});

  useEffect(() => {
    const el = ref.current;
    if (!el || !nodeId) return;
    void (async () => {
      const node = getBlock(nodeId);
      if (!node) {
        setStyle({
          opacity: '0',
          pointerEvents: 'none',
        });
        return;
      } else {
        let top = 2;

        if (node.type === BlockType.HeadingBlock) {
          const nodeData = node.data as HeadingBlockData;
          top = headingBlockTopOffset[nodeData.level];
        }

        setStyle({
          opacity: '1',
          pointerEvents: 'auto',
          top: `${top}px`,
        });
      }
    })();
  }, [dispatch, nodeId]);

  const handleMouseMove = useCallback((e: MouseEvent) => {
    const { clientX, clientY } = e;
    const id = getNodeIdByPoint(clientX, clientY);
    setHoverNodeId(id);
  }, []);

  useEffect(() => {
    container.addEventListener('mousemove', handleMouseMove);
    return () => {
      container.removeEventListener('mousemove', handleMouseMove);
    };
  }, [container, handleMouseMove]);

  return {
    nodeId,
    ref,
    style,
  };
}

function getNodeIdByPoint(x: number, y: number) {
  const viewportNodes = document.querySelectorAll('[data-block-id]');
  let node: {
    el: Element;
    rect: DOMRect;
  } | null = null;
  viewportNodes.forEach((el) => {
    const rect = el.getBoundingClientRect();

    if (rect.x + rect.width - 1 >= x && rect.y + rect.height - 1 >= y && rect.y <= y) {
      if (!node || rect.y > node.rect.y) {
        node = {
          el,
          rect,
        };
      }
    }
  });
  return node
    ? (
        node as {
          el: Element;
          rect: DOMRect;
        }
      ).el.getAttribute('data-block-id')
    : null;
}

const origin: {
  anchorOrigin: PopoverOrigin;
  transformOrigin: PopoverOrigin;
} = {
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'right',
  },
  transformOrigin: {
    vertical: 'bottom',
    horizontal: 'left',
  },
};
export function usePopover() {
  const [anchorEl, setAnchorEl] = React.useState<HTMLButtonElement | null>(null);

  const onClose = useCallback(() => {
    setAnchorEl(null);
  }, []);

  const handleOpen = useCallback((e: React.MouseEvent<HTMLButtonElement>) => {
    e.preventDefault();
    setAnchorEl(e.currentTarget);
  }, []);

  const open = Boolean(anchorEl);

  return {
    anchorEl,
    onClose,
    open,
    handleOpen,
    disableAutoFocus: true,
    ...origin,
  };
}
