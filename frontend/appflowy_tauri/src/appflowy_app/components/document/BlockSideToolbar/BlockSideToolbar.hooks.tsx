import { BlockType, HeadingBlockData, NestedBlock } from "@/appflowy_app/interfaces/document";
import { useAppDispatch } from "@/appflowy_app/stores/store";
import { useCallback, useEffect, useRef, useState } from 'react';
import { getBlockByIdThunk } from "$app_reducers/document/async-actions";

const headingBlockTopOffset: Record<number, number> = {
  1: 7,
  2: 6,
  3: 3,
};
export function useBlockSideToolbar({ container }: { container: HTMLDivElement }) {
  const [nodeId, setHoverNodeId] = useState<string | null>(null);
  const [menuOpen, setMenuOpen] = useState(false);
  const ref = useRef<HTMLDivElement | null>(null);
  const dispatch = useAppDispatch();
  const [style, setStyle] = useState<React.CSSProperties>({});

  useEffect(() => {
    const el = ref.current;
    if (!el || !nodeId) return;
    void(async () => {
      const{ payload: node } = await dispatch(getBlockByIdThunk(nodeId)) as {
        payload: NestedBlock;
      };
      if (!node) {
        setStyle({
          opacity: '0',
          pointerEvents: 'none',
        });
        return;
      } else {
        let top = 1;

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

  const handleToggleMenu = useCallback((isOpen: boolean) => {
    setMenuOpen(isOpen);
    if (!isOpen) {
      setHoverNodeId('');
    }
  }, []);

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
    handleToggleMenu,
    menuOpen,
    style
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
