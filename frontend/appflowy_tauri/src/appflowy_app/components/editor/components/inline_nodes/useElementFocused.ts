import { ReactEditor, useSelected, useSlate } from 'slate-react';
import { useMemo } from 'react';
import { Range, Text, Element } from 'slate';

export function useElementFocused(node: Element) {
  const editor = useSlate();
  const text = (node.children[0] as Text).text;
  const selected = useSelected();

  const focused = useMemo(() => {
    if (!selected) return false;
    const selection = editor.selection;

    if (!selection) return false;
    const path = ReactEditor.findPath(editor, node);
    const range = { anchor: { path, offset: 0 }, focus: { path, offset: text.length } } as Range;

    return Range.includes(range, selection);
  }, [editor, selected, node, text.length]);

  return focused;
}
