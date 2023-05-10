import { useTextInput } from '../_shared/Text/TextInput.hooks';
import { useTextBlockKeyEvent } from '$app/components/document/TextBlock/events/Events.hooks';

export function useTextBlock(id: string) {
  const { editor, onChange, value, onDOMBeforeInput } = useTextInput(id);
  const { onKeyDown } = useTextBlockKeyEvent(id, editor);

  return {
    onChange,
    onKeyDown,
    onDOMBeforeInput,
    editor,
    value,
  };
}
