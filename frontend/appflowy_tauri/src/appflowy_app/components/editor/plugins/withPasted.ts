import { ReactEditor } from 'slate-react';
import { convertBlockToJson } from '$app/application/document/document.service';
import { Editor, Element, NodeEntry, Path, Location, Range } from 'slate';
import { generateId } from '$app/components/editor/provider/utils/convert';
import { EditorNodeType } from '$app/application/document/document.types';
import { InputType } from '@/services/backend';

export function withPasted(editor: ReactEditor) {
  const { insertData } = editor;

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

  editor.insertFragment = (fragment, options = {}) => {
    Editor.withoutNormalizing(editor, () => {
      const { at = getDefaultInsertLocation(editor) } = options;

      if (!fragment.length) {
        return;
      }

      if (Range.isRange(at) && !Range.isCollapsed(at)) {
        editor.delete({
          unit: 'character',
        });
      }

      const mergedText = editor.above({
        match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.type === EditorNodeType.Text,
      }) as NodeEntry<
        Element & {
          textId: string;
        }
      >;

      if (!mergedText) return;

      const [mergedTextNode, mergedTextNodePath] = mergedText;

      const traverse = (node: Element) => {
        if (node.type === EditorNodeType.Text) {
          node.textId = generateId();
          return;
        }

        node.blockId = generateId();
        node.children?.forEach((child) => traverse(child as Element));
      };

      fragment?.forEach((node) => traverse(node as Element));

      const firstNode = fragment[0] as Element;

      if (firstNode && firstNode.type !== 'text') {
        if (firstNode.children && firstNode.children.length > 0) {
          const [textNode, ...children] = firstNode.children;

          fragment[0] = textNode;
          fragment.splice(1, 0, ...children);
        } else {
          fragment.unshift(getEmptyText());
        }
      }

      editor.insertNodes((fragment[0] as Element).children, {
        at: [...mergedTextNodePath, mergedTextNode.children.length],
      });
      editor.select(mergedTextNodePath);
      editor.collapse({
        edge: 'end',
      });
      const otherNodes = fragment.slice(1);

      if (otherNodes.length > 0) {
        const parentPath = Path.parent(mergedTextNodePath);

        const nextPath = Path.next(parentPath);
        const lastNodeText = (otherNodes[otherNodes.length - 1] as Element).children?.[0] as Element;

        let canSelect = true;

        if (!lastNodeText || lastNodeText.type !== EditorNodeType.Text) {
          canSelect = false;
        }

        editor.insertNodes(otherNodes, {
          at: nextPath,
          select: canSelect,
        });

        if (canSelect) {
          editor.collapse({
            edge: 'end',
          });
        }
      }
    });
  };

  return editor;
}

function getEmptyText(): Element {
  return {
    type: EditorNodeType.Text,
    textId: generateId(),
    children: [
      {
        text: '',
      },
    ],
  };
}

export const getDefaultInsertLocation = (editor: Editor): Location => {
  if (editor.selection) {
    return editor.selection;
  } else if (editor.children.length > 0) {
    return Editor.end(editor, []);
  } else {
    return [0];
  }
};
