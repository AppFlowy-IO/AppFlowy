import { ReactEditor } from 'slate-react';
import { Editor, Element, Node, NodeEntry, Transforms } from 'slate';
import { Log } from '$app/utils/log';
import { generateId } from '$app/components/editor/provider/utils/convert';

export function withPasted(editor: ReactEditor) {
  const { insertData, mergeNodes } = editor;

  editor.mergeNodes = (...args) => {
    const isBlock = (n: Node) =>
      !Editor.isEditor(n) && Element.isElement(n) && n.type !== undefined && n.level !== undefined;

    const [match] = Editor.nodes(editor, {
      match: isBlock,
    });

    const node = match ? (match[0] as Element) : null;

    if (!node) {
      mergeNodes(...args);
      return;
    }

    // This is a hack to fix the bug that the children of the node will be moved to the previous node
    const previous = Editor.previous(editor, {
      match: (n) => {
        return !Editor.isEditor(n) && Element.isElement(n) && n.type !== undefined && n.level === (node.level ?? 1) - 1;
      },
    });

    if (previous) {
      const [previousNode] = previous as NodeEntry<Element>;

      if (previousNode && previousNode.blockId !== node.parentId) {
        const children = editor.children.filter((child) => (child as Element).parentId === node.parentId);

        children.forEach((child) => {
          const childIndex = editor.children.findIndex((c) => c === child);
          const childPath = [childIndex];

          Transforms.setNodes(editor, { parentId: previousNode.blockId }, { at: childPath });
        });
      }
    }

    mergeNodes(...args);
  };

  editor.insertData = (data) => {
    const fragment = data.getData('application/x-slate-fragment');

    try {
      if (fragment) {
        const decoded = decodeURIComponent(window.atob(fragment));
        const parsed = JSON.parse(decoded);

        if (parsed instanceof Array) {
          const idMap = new Map<string, string>();

          for (const parsedElement of parsed as Element[]) {
            if (!parsedElement.blockId) continue;
            const newBlockId = generateId();

            if (parsedElement.parentId) {
              parsedElement.parentId = idMap.get(parsedElement.parentId) ?? parsedElement.parentId;
            }

            idMap.set(parsedElement.blockId, newBlockId);
            parsedElement.blockId = newBlockId;

            parsedElement.textId = generateId();
          }

          editor.insertFragment(parsed);
          return;
        }
      }
    } catch (err) {
      Log.error('insertData', err);
    }

    insertData(data);
  };

  return editor;
}
