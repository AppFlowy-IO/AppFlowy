import { useCallback, useEffect } from 'react';
import isHotkey from 'is-hotkey';
import { Keyboard } from '@/appflowy_app/constants/document/keyboard';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

export function useUndoRedo(container: HTMLDivElement) {
  const { controller } = useSubscribeDocument();

  const onUndo = useCallback(async () => {
    if (!controller) return;
    await controller.undo();
  }, [controller]);

  const onRedo = useCallback(async () => {
    if (!controller) return;
    await controller.redo();
  }, [controller]);

  const handleKeyDownCapture = useCallback(
    async (e: KeyboardEvent) => {
      if (isHotkey(Keyboard.keys.UNDO, e)) {
        e.stopPropagation();
        await onUndo();
      }

      if (isHotkey(Keyboard.keys.REDO, e)) {
        e.stopPropagation();
        await onRedo();
      }
    },
    [onRedo, onUndo]
  );

  useEffect(() => {
    container.addEventListener('keydown', handleKeyDownCapture, true);
    return () => {
      container.removeEventListener('keydown', handleKeyDownCapture, true);
    };
  }, [container, handleKeyDownCapture]);
}
