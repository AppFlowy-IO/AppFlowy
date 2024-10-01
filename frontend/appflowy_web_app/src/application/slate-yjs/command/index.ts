import { InlineBlockType, Mention, MentionType } from '@/application/types';
import { FormulaNode } from '@/components/editor/editor.type';
import { renderDate } from '@/utils/time';
import { Editor, Element, Text, Node, NodeEntry } from 'slate';
import { ReactEditor } from 'slate-react';

export const CustomEditor = {
  findTextNode (editor: ReactEditor, path: number[]): NodeEntry<Element> {
    const [node] = editor.nodes({
      at: path,
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.textId !== undefined,
    });

    return node as NodeEntry<Element>;
  },
  // Get the text content of a block node, including the text content of its children and formula nodes
  getBlockTextContent (node: Node): string {
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
      if (node.formula) {
        return node.formula;
      }

      if (node.mention) {
        if (node.mention.type === MentionType.Date) {
          const date = node.mention.date || '';
          const isUnix = date?.length === 10;

          return renderDate(date, 'MMM DD, YYYY', isUnix);
        } else {
          const name = document.querySelector('[data-mention-id="' + node.mention.page_id + '"]')?.textContent || '';

          return name;
        }
      }

      return node.text || '';
    }

    return node.children.map((n) => CustomEditor.getBlockTextContent(n)).join('');
  },
};
