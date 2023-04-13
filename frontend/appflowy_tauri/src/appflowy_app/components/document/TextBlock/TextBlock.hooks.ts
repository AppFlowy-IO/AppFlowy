import { triggerHotkey } from '@/appflowy_app/utils/slate/hotkey';
import { useCallback, useState } from 'react';
import { Descendant, Range } from 'slate';
import { TextDelta } from '$app/interfaces/document';
import { useTextInput } from '../_shared/TextInput.hooks';

export function useTextBlock(delta: TextDelta[]) {
  const { editor } = useTextInput(delta);
  const [value, setValue] = useState<Descendant[]>([]);

  const onChange = useCallback(
    (e: Descendant[]) => {
      setValue(e);
    },
    [editor]
  );

  const onKeyDownCapture = (event: React.KeyboardEvent<HTMLDivElement>) => {
    switch (event.key) {
      case 'Enter': {
        event.stopPropagation();
        event.preventDefault();
        return;
      }
      case 'Backspace': {
        if (!editor.selection) return;
        const { anchor } = editor.selection;
        const isCollapsed = Range.isCollapsed(editor.selection);
        if (isCollapsed && anchor.offset === 0 && anchor.path.toString() === '0,0') {
          event.stopPropagation();
          event.preventDefault();
          return;
        }
      }
    }
    triggerHotkey(event, editor);
  };

  const onDOMBeforeInput = useCallback((e: InputEvent) => {
    // COMPAT: in Apple, `compositionend` is dispatched after the `beforeinput` for "insertFromComposition".
    // It will cause repeated characters when inputting Chinese.
    // Here, prevent the beforeInput event and wait for the compositionend event to take effect.
    if (e.inputType === 'insertFromComposition') {
      e.preventDefault();
    }
  }, []);

  return {
    onChange,
    onKeyDownCapture,
    onDOMBeforeInput,
    editor,
    value,
  };
}
