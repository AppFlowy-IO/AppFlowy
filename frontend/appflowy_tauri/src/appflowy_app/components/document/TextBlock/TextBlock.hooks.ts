import { useTextInput } from '../_shared/Text/TextInput.hooks';
import { useTextBlockKeyEvent } from '$app/components/document/TextBlock/events/Events.hooks';

export function useTextBlock(id: string) {
  const { editor, ...rest } =
    useTextInput(id);
  const { onKeyDown } = useTextBlockKeyEvent(id, editor);

  return {
    onKeyDown,
    editor,
    ...rest
  };
}
