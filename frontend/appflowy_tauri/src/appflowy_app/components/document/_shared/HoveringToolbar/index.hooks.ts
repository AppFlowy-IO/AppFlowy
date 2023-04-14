import { useEffect, useRef } from 'react';
import { useFocused, useSlate } from 'slate-react';
import { calcToolbarPosition } from '$app/utils/slate/toolbar';
export function useHoveringToolbar(id: string) {
  const editor = useSlate();
  const inFocus = useFocused();
  const ref = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const nodeRect = document.querySelector(`[data-block-id="${id}"]`)?.getBoundingClientRect();

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
    editor,
  };
}
