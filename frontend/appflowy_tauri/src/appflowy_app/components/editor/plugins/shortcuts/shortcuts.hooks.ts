import { ReactEditor } from 'slate-react';
import { useCallback, KeyboardEvent } from 'react';
import {
  EditorMarkFormat,
  EditorNodeType,
  TodoListNode,
  ToggleListNode,
} from '$app/application/document/document.types';
import isHotkey from 'is-hotkey';
import { getBlock } from '$app/components/editor/plugins/utils';
import { SOFT_BREAK_TYPES } from '$app/components/editor/plugins/constants';
import { CustomEditor } from '$app/components/editor/command';
import { getHotKeys } from '$app/components/editor/plugins/shortcuts/hotkey';

/**
 * Hotkeys shortcuts
 * @description [getHotKeys] is defined in [hotkey.ts]
 * - bold: Mod+b
 * - italic: Mod+i
 * - underline: Mod+u
 * - strikethrough: Mod+Shift+s
 * - code: Mod+Shift+c
 * - align left: Mod+Shift+l
 * - align center: Mod+Shift+e
 * - align right: Mod+Shift+r
 * - indent: Tab
 * - outdent: Shift+Tab
 * - split block: Enter
 * - insert \n: Shift+Enter
 * - toggle todo or toggle: Mod+Enter (toggle todo list or toggle list)
 */

export function useShortcuts(editor: ReactEditor) {
  const onKeyDown = useCallback(
    (e: KeyboardEvent<HTMLDivElement>) => {
      Object.entries(getHotKeys()).forEach(([_, item]) => {
        if (isHotkey(item.hotkey, e)) {
          e.stopPropagation();
          e.preventDefault();
          if (CustomEditor.selectionIncludeRoot(editor)) return;
          if (item.markKey === EditorMarkFormat.Align) {
            CustomEditor.toggleAlign(editor, item.markValue as string);
            return;
          }

          CustomEditor.toggleMark(editor, {
            key: item.markKey,
            value: item.markValue,
          });
          return;
        }
      });

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

      if (isHotkey('mod+Enter', e) && node) {
        if (node.type === EditorNodeType.TodoListBlock) {
          e.preventDefault();
          CustomEditor.toggleTodo(editor, node as TodoListNode);
          return;
        }

        if (node.type === EditorNodeType.ToggleListBlock) {
          e.preventDefault();
          CustomEditor.toggleToggleList(editor, node as ToggleListNode);
          return;
        }
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
