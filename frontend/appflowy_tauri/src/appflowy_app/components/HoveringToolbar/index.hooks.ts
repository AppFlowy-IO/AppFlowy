import { useEffect, useRef } from 'react';
import { useFocused, useSlate } from 'slate-react';
import { calcToolbarPosition } from '@/appflowy_app/utils/slate/toolbar';
import { TreeNode } from '$app/block_editor/view/tree_node';

export function useHoveringToolbar({node}: {
  node: TreeNode
}) {
  const editor = useSlate();
  const inFocus = useFocused();
  const ref = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const nodeRect = document.querySelector(`[data-block-id=${node.id}]`)?.getBoundingClientRect();

    if (!nodeRect) return;
    const position = calcToolbarPosition(editor, el, nodeRect);

    if (!position) {
      el.style.opacity = '0';
      el.style.zIndex = '-1';
    } else {
      el.style.opacity = '1';
      el.style.zIndex = '1';
      el.style.top = position.top;
      el.style.left = position.left;
    }
  });
  return {
    ref,
    inFocus,
    editor
  }
}