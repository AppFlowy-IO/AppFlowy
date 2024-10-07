import { useCallback, useMemo } from 'react';
import { Editor, Range, Text, Transforms } from 'slate';
import { ReactEditor, useReadOnly, useSelected, useSlate } from 'slate-react';

export function useLeafSelected (text: Text) {
  const readonly = useReadOnly();
  const editor = useSlate();
  const elementIsSelected = useSelected();
  const selection = editor.selection;

  const isCursorBefore = useMemo(() => {
    if (readonly || !selection || !text) return false;

    if (selection && Range.isCollapsed(selection)) {
      const path = ReactEditor.findPath(editor, text);
      const start = Editor.start(editor, path);

      return Range.equals(selection, {
        anchor: start,
        focus: start,
      });
    }

    return false;
  }, [editor, readonly, selection, text]);

  const isCursorAfter = useMemo(() => {
    if (readonly || !selection || !text) return false;
    if (selection && Range.isCollapsed(selection)) {
      const path = ReactEditor.findPath(editor, text);
      const end = Editor.end(editor, path);

      return Range.equals(selection, {
        anchor: end,
        focus: end,
      });
    }

    return false;
  }, [editor, readonly, selection, text]);

  const isSelected = useMemo(() => {
    if (readonly || !selection || !elementIsSelected || !text) return false;

    try {
      const path = ReactEditor.findPath(editor, text);

      if (Range.isCollapsed(selection)) return false;

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
    isCursorBefore,
    isCursorAfter,
  };
}