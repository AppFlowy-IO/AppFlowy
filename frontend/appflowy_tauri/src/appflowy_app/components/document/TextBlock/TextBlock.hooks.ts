import { useCallback } from 'react';
import { useTextInput } from '../_shared/TextInput.hooks';
import { useTextBlockKeyEvent } from '$app/components/document/TextBlock/events/Events.hooks';

export function useTextBlock(id: string) {
  const { editor, onChange, value } = useTextInput(id);
  const { onKeyDown } = useTextBlockKeyEvent(id, editor);

  const onKeyDownCapture = useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>) => {
      onKeyDown(event);
    },
    [onKeyDown]
  );

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
