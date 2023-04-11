import { useEffect, useRef } from 'react';
import { useFocused, useSlate } from 'slate-react';
<<<<<<<< HEAD:frontend/appflowy_tauri/src/appflowy_app/components/document/_shared/HoveringToolbar/index.hooks.ts
import { calcToolbarPosition } from '$app/utils/slate/toolbar';

========
import { calcToolbarPosition } from '@/appflowy_app/utils/slate/toolbar';


>>>>>>>> 341dce67d45ebe46ae55e11349a19191ac99b4cf:frontend/appflowy_tauri/src/appflowy_app/components/document/HoveringToolbar/index.hooks.ts
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
