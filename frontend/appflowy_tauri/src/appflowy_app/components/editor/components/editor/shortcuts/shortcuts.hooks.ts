import { ReactEditor } from 'slate-react';
import { useCallback, KeyboardEvent } from 'react';
import { EditorMarkFormat, EditorNodeType } from '$app/application/document/document.types';
import isHotkey from 'is-hotkey';

import { getBlock } from '$app/components/editor/plugins/utils';
import { SOFT_BREAK_TYPES } from '$app/components/editor/plugins/constants';
import { CustomEditor } from '$app/components/editor/command';

const inputTypeToFormat: Record<string, EditorMarkFormat> = {
  formatBold: EditorMarkFormat.Bold,
  formatItalic: EditorMarkFormat.Italic,
  formatUnderline: EditorMarkFormat.Underline,
  formatStrikethrough: EditorMarkFormat.StrikeThrough,
  formatCode: EditorMarkFormat.Code,
};

const hotKeys = {
  formatBold: 'Mod+b',
  formatItalic: 'Mod+i',
  formatUnderline: 'Mod+u',
  formatStrikethrough: 'Mod+Shift+s',
  formatCode: 'Mod+Shift+c',
};

export function useShortcuts(editor: ReactEditor) {
  const onDOMBeforeInput = useCallback(
    (e: InputEvent) => {
      const inputType = e.inputType;

      const format = inputTypeToFormat[inputType];

      if (format) {
        e.preventDefault();
        return CustomEditor.toggleMark(editor, {
          key: format,
          value: true,
        });
      }
    },
    [editor]
  );

  const onKeyDown = useCallback(
    (e: KeyboardEvent<HTMLDivElement>) => {
      const isAppleWebkit = navigator.userAgent.includes('AppleWebKit');

      // Apple Webkit does not support the input event for formatting
      if (isAppleWebkit) {
        Object.entries(hotKeys).forEach(([key, hotkey]) => {
          if (isHotkey(hotkey, e)) {
            e.preventDefault();
            CustomEditor.toggleMark(editor, {
              key: inputTypeToFormat[key],
              value: true,
            });
          }
        });
      }

      const node = getBlock(editor);

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
    },
    [editor]
  );

  return {
    onDOMBeforeInput,
    onKeyDown,
  };
}
