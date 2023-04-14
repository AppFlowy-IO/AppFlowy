import { BlockType, HeadingBlockData } from '@/appflowy_app/interfaces/document';
import { useAppSelector } from '@/appflowy_app/stores/store';
import { debounce } from '@/appflowy_app/utils/tool';
import { useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { Node } from '@/appflowy_app/stores/reducers/document/slice';
import { v4 } from 'uuid';

export function useBlockSideTools({ container }: { container: HTMLDivElement }) {
  const [nodeId, setHoverNodeId] = useState<string>('');
  const ref = useRef<HTMLDivElement | null>(null);
  const nodes = useAppSelector((state) => state.document.nodes);
  const { insertAfter } = useController();

  const handleMouseMove = useCallback((e: MouseEvent) => {
    const { clientX, clientY } = e;
    const x = clientX;
    const y = clientY;
    const id = getNodeIdByPoint(x, y);
    if (!id) {
      setHoverNodeId('');
    } else {
      if ([BlockType.ColumnBlock].includes(nodes[id].type)) {
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

    const node = nodes[nodeId];
    if (!node) {
      el.style.opacity = '0';
      el.style.zIndex = '-1';
    } else {
      el.style.opacity = '1';
      el.style.zIndex = '1';
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
  }, [nodeId, nodes]);

  const handleAddClick = useCallback(() => {
    if (!nodeId) return;
    insertAfter(nodes[nodeId]);
  }, [nodeId, nodes]);

  useEffect(() => {
    container.addEventListener('mousemove', debounceMove);
    return () => {
      container.removeEventListener('mousemove', debounceMove);
    };
  }, [debounceMove]);

  return {
    nodeId,
    ref,
    handleAddClick,
  };
}

function useController() {
  const controller = useContext(DocumentControllerContext);

  const insertAfter = useCallback((node: Node) => {
    const parentId = node.parent;
    if (!parentId || !controller) return;

    //
  }, []);

  return {
    insertAfter,
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
