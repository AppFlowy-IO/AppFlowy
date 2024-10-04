import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { EditorMarkFormat } from '@/application/slate-yjs/types';
import { getBlockEntry } from '@/application/slate-yjs/utils/yjsOperations';
import { BlockType } from '@/application/types';
import { createHotkey, HOT_KEY_NAME } from '@/utils/hotkeys';
import { useCallback, KeyboardEvent } from 'react';
import { ReactEditor, useReadOnly } from 'slate-react';

const SOFT_BREAK_TYPES = [BlockType.CalloutBlock, BlockType.CodeBlock];

export function useShortcuts (editor: ReactEditor) {
  const yjsEditor = editor as YjsEditor;
  const readOnly = useReadOnly();
  const onKeyDown = useCallback((event: KeyboardEvent<HTMLDivElement>) => {
    const e = event.nativeEvent;
    const { selection } = editor;

    if (!selection) return;
    const [point, endPoint] = editor.edges(selection);
    const node = getBlockEntry(yjsEditor, point);
    const endNode = getBlockEntry(yjsEditor, endPoint);
    const isSameBlock = node[0].blockId === endNode[0].blockId;

    switch (true) {
      /**
       * Escape: Esc
       * Default behavior: Deselect editor
       */
      case createHotkey(HOT_KEY_NAME.ESCAPE)(e):
        editor.deselect();
        break;
      /**
       * Indent block: Tab
       * Default behavior: Indent block
       */
      case createHotkey(HOT_KEY_NAME.INDENT_BLOCK)(e):
        event.preventDefault();

        if (readOnly || !isSameBlock) return;
        if (SOFT_BREAK_TYPES.includes(node[0]?.type as BlockType)) {
          editor.insertText('\t');
          break;
        }

        CustomEditor.tabForward(yjsEditor, point);
        break;
      /**
       * Outdent block: Shift+Tab
       * Default behavior: Outdent block
       */
      case createHotkey(HOT_KEY_NAME.OUTDENT_BLOCK)(e):
        event.preventDefault();
        if (readOnly || !isSameBlock) return;
        CustomEditor.tabBackward(yjsEditor, point);
        break;
      /**
       * Split block: Enter
       * Default behavior: Split block
       * Special case for soft break types: Insert \n
       */
      case createHotkey(HOT_KEY_NAME.SPLIT_BLOCK)(e):
        if (readOnly) break;
        if (SOFT_BREAK_TYPES.includes(node[0]?.type as BlockType)) {
          event.preventDefault();
          editor.insertText('\n');
        }

        break;
      /**
       * Insert soft break: Shift+Enter
       * Default behavior: Insert \n
       * Special case for soft break types: Split block
       */
      case createHotkey(HOT_KEY_NAME.INSERT_SOFT_BREAK)(e):
        if (readOnly) break;
        event.preventDefault();
        if (node && SOFT_BREAK_TYPES.includes(node[0]?.type as BlockType)) {
          editor.insertBreak();
        } else {
          editor.insertText('\n');
        }

        break;
      /**
       * Toggle todo: Mod+Enter
       * Default behavior: Toggle todo
       * Special case for toggle list block: Toggle collapse
       */
      case createHotkey(HOT_KEY_NAME.TOGGLE_TODO)(e):
      case createHotkey(HOT_KEY_NAME.TOGGLE_COLLAPSE)(e):
        if (readOnly) break;
        event.preventDefault();

        if (node[0].type === BlockType.ToggleListBlock) {
          CustomEditor.toggleToggleList(yjsEditor, node[0].blockId as string);
        } else if (node[0].type === BlockType.TodoListBlock) {
          CustomEditor.toggleTodoList(yjsEditor, node[0].blockId as string);
        }

        break;
      /**
       * Bold: Mod + B
       */
      case createHotkey(HOT_KEY_NAME.BOLD)(e):
        event.preventDefault();
        if (readOnly) break;
        CustomEditor.toggleMark(editor, {
          key: EditorMarkFormat.Bold,
          value: true,
        });
        break;
      /**
       * Italic: Mod + I
       */
      case createHotkey(HOT_KEY_NAME.ITALIC)(e):
        event.preventDefault();
        CustomEditor.toggleMark(editor, {
          key: EditorMarkFormat.Italic,
          value: true,
        });
        break;
      /**
       * Underline: Mod + U
       */
      case createHotkey(HOT_KEY_NAME.UNDERLINE)(e):
        event.preventDefault();
        CustomEditor.toggleMark(editor, {
          key: EditorMarkFormat.Underline,
          value: true,
        });
        break;
      /**
       * Strikethrough: Mod + Shift + S / Mod + Shift + X
       */
      case createHotkey(HOT_KEY_NAME.STRIKETHROUGH)(e):
        event.preventDefault();
        CustomEditor.toggleMark(editor, {
          key: EditorMarkFormat.StrikeThrough,
          value: true,
        });
        break;
      /**
       * Code: Mod + E
       */
      case createHotkey(HOT_KEY_NAME.CODE)(e):
        event.preventDefault();
        CustomEditor.toggleMark(editor, {
          key: EditorMarkFormat.Code,
          value: true,
        });
        break;
      default:
        break;
    }
  }, [editor, yjsEditor, readOnly]);

  return {
    onKeyDown,
  };
}