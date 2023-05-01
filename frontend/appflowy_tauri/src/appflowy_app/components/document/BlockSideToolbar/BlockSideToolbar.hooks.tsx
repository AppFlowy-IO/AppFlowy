import { BlockType, HeadingBlockData } from '@/appflowy_app/interfaces/document';
import { useAppSelector } from '@/appflowy_app/stores/store';
import { debounce } from '@/appflowy_app/utils/tool';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';

export function useBlockSideToolbar({ container }: { container: HTMLDivElement }) {
  const [nodeId, setHoverNodeId] = useState<string>('');
  const [menuOpen, setMenuOpen] = useState(false);
  const ref = useRef<HTMLDivElement | null>(null);
  const nodes = useAppSelector((state) => state.document.nodes);
  const nodesRef = useRef(nodes);

  const handleMouseMove = useCallback((e: MouseEvent) => {
    const { clientX, clientY } = e;
    const x = clientX;
    const y = clientY;
    const id = getNodeIdByPoint(x, y);
    if (!id) {
      setHoverNodeId('');
    } else {
      if ([BlockType.ColumnBlock].includes(nodesRef.current[id].type)) {
        setHoverNodeId('');
        return;
      }
      setHoverNodeId(id);
    }
  }, []);

  const debounceMove = useMemo(() => debounce(handleMouseMove, 30), [handleMouseMove]);

  useEffect(() => {
    const el = ref.current;
    if (!el || !nodeId) return;

    const node = nodesRef.current[nodeId];
    if (!node) {
      el.style.opacity = '0';
      el.style.pointerEvents = 'none';
    } else {
      el.style.opacity = '1';
      el.style.pointerEvents = 'auto';
      el.style.top = '1px';
      if (node?.type === BlockType.HeadingBlock) {
        const nodeData = node.data as HeadingBlockData;
        if (nodeData.level === 1) {
          el.style.top = '8px';
        } else if (nodeData.level === 2) {
          el.style.top = '6px';
        } else {
          el.style.top = '5px';
        }
      }
    }
  }, [nodeId]);

  const handleToggleMenu = useCallback((isOpen: boolean) => {
    setMenuOpen(isOpen);
    if (!isOpen) {
      setHoverNodeId('');
    }
  }, []);

  useEffect(() => {
    container.addEventListener('mousemove', debounceMove);
    return () => {
      container.removeEventListener('mousemove', debounceMove);
    };
  }, [debounceMove]);

  useEffect(() => {
    nodesRef.current = nodes;
  }, [nodes]);

  return {
    nodeId,
    ref,
    handleToggleMenu,
    menuOpen,
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
