import { InlineBlockType, Mention, MentionType } from '@/application/collab.type';
import { FormulaNode } from '@/components/editor/editor.type';
import { renderDate } from '@/utils/time';
import { Editor, Transforms, Element, Text, Node } from 'slate';
import { ReactEditor } from 'slate-react';

export const CustomEditor = {
  setDocumentTitle: (editor: ReactEditor, title: string) => {
    const length = Editor.string(editor, [0, 0]).length;

    Transforms.insertText(editor, title, {
      at: {
        anchor: { path: [0, 0, 0], offset: 0 },
        focus: { path: [0, 0, 0], offset: length },
      },
    });
  },

  // Get the text content of a block node, including the text content of its children and formula nodes
  getBlockTextContent(node: Node): string {
    if (Element.isElement(node)) {
      if (node.type === InlineBlockType.Formula) {
        return (node as FormulaNode).data || '';
      }

      if (node.type === InlineBlockType.Mention && (node.data as Mention)?.type === MentionType.Date) {
        const date = (node.data as Mention).date || '';
        const isUnix = date?.length === 10;

        return renderDate(date, 'MMM DD, YYYY', isUnix);
      }
    }

    if (Text.isText(node)) {
      return node.text || '';
    }

    return node.children.map((n) => CustomEditor.getBlockTextContent(n)).join('');
  },
};
