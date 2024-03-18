import { ReactEditor } from 'slate-react';
import { useCallback, KeyboardEvent } from 'react';
import { EditorNodeType, ToggleListNode } from '$app/application/document/document.types';
import isHotkey from 'is-hotkey';
import { getBlock } from '$app/components/editor/plugins/utils';
import { SOFT_BREAK_TYPES } from '$app/components/editor/plugins/constants';
import { CustomEditor } from '$app/components/editor/command';
import { createHotkey, HOT_KEY_NAME } from '$app/utils/hotkeys';

/**
 * Hotkeys shortcuts
 * @description [getHotKeys] is defined in [hotkey.ts]
 * - indent: Tab
 * - outdent: Shift+Tab
 * - split block: Enter
 * - insert \n: Shift+Enter
 * - toggle todo or toggle: Mod+Enter (toggle todo list or toggle list)
 */

export function useShortcuts(editor: ReactEditor) {
  const onKeyDown = useCallback(
    (e: KeyboardEvent<HTMLDivElement>) => {
      const node = getBlock(editor);

      if (isHotkey('Escape', e)) {
        e.preventDefault();

        editor.deselect();

        return;
      }

      if (isHotkey('Tab', e)) {
        e.preventDefault();
        if (SOFT_BREAK_TYPES.includes(node?.type as EditorNodeType)) {
          editor.insertText('\t');
          return;
        }

        return CustomEditor.tabForward(editor);
      }

      if (isHotkey('shift+Tab', e)) {
        e.preventDefault();
        return CustomEditor.tabBackward(editor);
      }

      if (isHotkey('Enter', e)) {
        if (SOFT_BREAK_TYPES.includes(node?.type as EditorNodeType)) {
          e.preventDefault();
          editor.insertText('\n');
          return;
        }
      }

      if (isHotkey('shift+Enter', e) && node) {
        e.preventDefault();
        if (SOFT_BREAK_TYPES.includes(node.type as EditorNodeType)) {
          editor.splitNodes({
            always: true,
          });
        } else {
          editor.insertText('\n');
        }

        return;
      }

      if (createHotkey(HOT_KEY_NAME.TOGGLE_TODO)(e.nativeEvent)) {
        e.preventDefault();
        CustomEditor.toggleTodo(editor);
      }

      if (
        createHotkey(HOT_KEY_NAME.TOGGLE_COLLAPSE)(e.nativeEvent) &&
        node &&
        node.type === EditorNodeType.ToggleListBlock
      ) {
        e.preventDefault();
        CustomEditor.toggleToggleList(editor, node as ToggleListNode);
      }

      if (isHotkey('shift+backspace', e)) {
        e.preventDefault();
        e.stopPropagation();

        editor.deleteBackward('character');
        return;
      }
    },
    [editor]
  );

  return {
    onKeyDown,
  };
}
