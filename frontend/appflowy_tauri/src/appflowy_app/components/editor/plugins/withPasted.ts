import { ReactEditor } from 'slate-react';
import { convertBlockToJson } from '$app/application/document/document.service';
import { Editor, Element, NodeEntry } from 'slate';
import { generateId } from '$app/components/editor/provider/utils/convert';
import { EditorNodeType } from '$app/application/document/document.types';
import { InputType } from '@/services/backend';

export function withPasted(editor: ReactEditor) {
  const { insertData, insertFragment } = editor;

  editor.insertData = (data) => {
    const fragment = data.getData('application/x-slate-fragment');

    if (fragment) {
      insertData(data);
      return;
    }

    const html = data.getData('text/html');
    const text = data.getData('text/plain');
    const inputType = html ? InputType.Html : InputType.PlainText;

    if (html || text) {
      void convertBlockToJson(html || text, inputType).then((nodes) => {
        editor.insertFragment(nodes);
      });
      return;
    }

    insertData(data);
  };

  editor.insertFragment = (fragment) => {
    const mergedText = editor.above({
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.type === EditorNodeType.Text,
    }) as NodeEntry<
      Element & {
        textId: string;
      }
    >;

    if (!mergedText) return;

    const traverse = (node: Element) => {
      if (node.type === EditorNodeType.Text) {
        node.textId = generateId();
        return;
      }

      node.blockId = generateId();
      node.children.forEach((child) => traverse(child as Element));
    };

    fragment?.forEach((node) => traverse(node as Element));

    const firstNode = fragment[0] as Element;

    if (firstNode && firstNode.type !== 'text' && firstNode.children.length > 1) {
      const [textNode, ...children] = firstNode.children;

      fragment[0] = textNode;
      fragment.splice(1, 0, ...children);
    }

    return insertFragment(fragment);
  };

  return editor;
}
