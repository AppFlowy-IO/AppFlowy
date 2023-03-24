import { BlockEditor } from '@/appflowy_app/block_editor';
import { BlockType } from '@/appflowy_app/interfaces';
import { debounce } from '@/appflowy_app/utils/tool';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';

export function useBlockSideTools({ blockEditor, container }: { container: HTMLDivElement; blockEditor: BlockEditor }) {
  const [hoverBlock, setHoverBlock] = useState<string>();
  const ref = useRef<HTMLDivElement | null>(null);

  const handleMouseMove = useCallback((e: MouseEvent) => {
    const { clientX, clientY } = e;
    const x = clientX;
    const y = clientY + container.scrollTop;
    const block = blockEditor.renderTree.blockPositionManager?.getViewportBlockByPoint(x, y);

    if (!block) {
      setHoverBlock('');
    } else {
      const node = blockEditor.renderTree.getTreeNode(block.id)!;
      if ([BlockType.ColumnBlock].includes(node.type)) {
        setHoverBlock('');
      } else {
        setHoverBlock(block.id);
      }
    }
  }, []);

  const debounceMove = useMemo(() => debounce(handleMouseMove, 30), [handleMouseMove]);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    if (!hoverBlock) {
      el.style.opacity = '0';
      el.style.zIndex = '-1';
    } else {
      el.style.opacity = '1';
      el.style.zIndex = '1';
      const node = blockEditor.renderTree.getTreeNode(hoverBlock);
      el.style.top = '3px';
      if (node?.type === BlockType.HeadingBlock) {
        if (node.data.level === 1) {
          el.style.top = '8px';
        } else if (node.data.level === 2) {
          el.style.top = '6px';
        } else {
          el.style.top = '5px';
        }
      }
    }
  }, [hoverBlock]);

  useEffect(() => {
    container.addEventListener('mousemove', debounceMove);
    return () => {
      container.removeEventListener('mousemove', debounceMove);
    };
  }, [debounceMove]);

  return {
    hoverBlock,
    ref,
  };
}
