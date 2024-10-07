import { BaseRange, NodeEntry, Range, Text, Transforms } from 'slate';
import { ReactEditor } from 'slate-react';
import { TextInsertTextOptions } from 'slate/dist/interfaces/transforms/text';

export const withInsertText = (editor: ReactEditor) => {
  const { insertText } = editor;

  editor.insertText = (text: string, options?: TextInsertTextOptions) => {
    const newAt = (options?.at || editor.selection) as BaseRange;

    if (!newAt || !Range.isCollapsed(newAt)) {
      insertText(text, options);
      return;
    }

    const point = newAt.anchor;
    const [textEntry] = editor.nodes({
      at: point, match: n => {
        return Text.isText(n);
      },
    });
    const [textNode] = textEntry as NodeEntry<Text>;

    // If the text node is a formula or mention, split the node and insert the text
    if (textNode.formula || textNode.mention) {
      Transforms.splitNodes(editor, { at: point });
      Transforms.insertNodes(editor, { text }, { at: point, select: true, voids: false });

      return;
    }

    insertText(text, options);
  };

  return editor;
};