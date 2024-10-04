import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { getBlockEntry } from '@/application/slate-yjs/utils/yjsOperations';
import { BlockType } from '@/application/types';
import { createHotkey, HOT_KEY_NAME } from '@/utils/hotkeys';
import { useCallback, KeyboardEvent } from 'react';
import { ReactEditor } from 'slate-react';
import {
  Range,
} from 'slate';

const SOFT_BREAK_TYPES = [BlockType.CalloutBlock, BlockType.CodeBlock];

export function useShortcuts (editor: ReactEditor) {
  const yjsEditor = editor as YjsEditor;
  const onKeyDown = useCallback((event: KeyboardEvent<HTMLDivElement>) => {
    const e = event.nativeEvent;
    const { selection } = editor;

    if (!selection) return;
    const isExpanded = selection && Range.isExpanded(selection);
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
        e.preventDefault();

        if (!isSameBlock) return;
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
        e.preventDefault();
        if (!isSameBlock) return;
        CustomEditor.tabBackward(yjsEditor, point);
        break;
      default:
        break;
    }
  }, [yjsEditor, editor]);

  return {
    onKeyDown,
  };
}