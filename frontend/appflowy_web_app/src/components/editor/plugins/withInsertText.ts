import { BaseRange, NodeEntry, Point, Range, Text, Transforms } from 'slate';
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

    if (!textEntry) {
      insertText(text, options);
      return;
    }

    const [textNode, textPath] = textEntry as NodeEntry<Text>;

    // If the text node is a formula or mention, split the node and insert the text
    if (textNode.formula || textNode.mention) {
      console.log('Inserting text into formula or mention', newAt);
      Transforms.insertNodes(editor, { text }, { at: point, select: true, voids: false });

      return;
    }

    const end = editor.end(textPath);

    // If the point is after the end of the text node and the text node has a code or href attribute, insert the text as a new node
    if (!Point.isBefore(point, end) && (textNode.code || textNode.href)) {
      Transforms.insertNodes(editor, { text }, { at: point, select: true, voids: false });
      return;
    }

    insertText(text, options);
  };

  return editor;
};