import { useCallback, useMemo } from 'react';
import { Editor, Range, Text, Transforms } from 'slate';
import { ReactEditor, useReadOnly, useSelected, useSlate } from 'slate-react';

export function useLeafSelected (text: Text) {
  const readonly = useReadOnly();
  const editor = useSlate();
  const elementIsSelected = useSelected();
  const selection = editor.selection;

  const isSelected = useMemo(() => {
    if (readonly || !selection || !elementIsSelected || !text) return false;

    try {
      const path = ReactEditor.findPath(editor, text);

      // get the start and end point of the mention
      const start = Editor.start(editor, path);
      const end = Editor.end(editor, path);

      // check if the selection is inside the mention
      return !!(Range.intersection(selection, {
        anchor: start,
        focus: end,
      }));
    } catch (e) {
      return false;
    }

  }, [editor, elementIsSelected, readonly, selection, text]);

  const select = useCallback(() => {
    if (readonly || !text) return;

    const path = ReactEditor.findPath(editor, text);
    const start = Editor.start(editor, path);

    ReactEditor.focus(editor);
    Transforms.select(editor, {
      anchor: start,
      focus: Editor.end(editor, path),
    });

  }, [editor, readonly, text]);

  return {
    isSelected,
    select,
  };
}