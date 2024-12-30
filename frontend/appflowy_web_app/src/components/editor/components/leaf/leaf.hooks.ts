import { createContext, useCallback, useMemo, useContext, useState } from 'react';
import { Editor, Point, Range, Text, Transforms } from 'slate';
import { ReactEditor, useReadOnly, useSelected, useSlate } from 'slate-react';

export const LeafContext = createContext<{
  openLinkPopover?: (text: Text) => void;
  closeLinkPopover?: () => void;
  linkOpen?: Text;
} | undefined>(undefined);

export function useLeafContext() {
  return useContext(LeafContext) || {
    openLinkPopover: () => undefined,
    closeLinkPopover: () => undefined,
    linkOpen: undefined,
  };
}

export function useLeafSelected(text: Text) {
  const readonly = useReadOnly();
  const editor = useSlate();
  const elementIsSelected = useSelected();
  const selection = editor.selection;

  const [isCursorBefore, setIsCursorBefore] = useState<boolean>(false);

  const isSelected = useMemo(() => {
    if (readonly || !selection || !elementIsSelected || !text) return false;

    try {
      const path = ReactEditor.findPath(editor, text);

      if (Range.isCollapsed(selection)) {
        const end = Editor.end(editor, path);
        const isAnchorBefore = Point.isBefore(editor.end(selection), end);

        setIsCursorBefore(isAnchorBefore);
        return false;
      }

      // get the start and end point of the mention
      const start = Editor.start(editor, path);
      const end = Editor.end(editor, path);

      // check if the selection is inside the mention
      const selected = !!(Range.intersection(selection, {
        anchor: start,
        focus: end,
      }));

      return selected;
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
  };
}