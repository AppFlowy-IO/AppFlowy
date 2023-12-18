import { ReactEditor } from 'slate-react';
import { Editor, Element, Node, NodeEntry, Transforms } from 'slate';
import { generateId } from '$app/components/editor/provider/utils/convert';
import { blockTypes, EditorNodeType } from '$app/application/document/document.types';

export function withPasted(editor: ReactEditor) {
  const { mergeNodes, insertFragment } = editor;

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

  editor.insertFragment = (fragment) => {
    const idMap = new Map<string, string>();

    let rootId = (editor.children[0] as Element)?.parentId;

    if (!rootId) {
      rootId = generateId();
      insertFragment([
        {
          type: EditorNodeType.Paragraph,
          children: [
            {
              text: '',
            },
          ],
          data: {},
          blockId: rootId,
          textId: generateId(),
          parentId: '',
          level: 1,
        },
      ]);
    }

    for (const parsedElement of fragment as Element[]) {
      const newBlockId = generateId();

      if (!blockTypes.includes(parsedElement.type)) {
        parsedElement.type = EditorNodeType.Paragraph;
      }

      if (parsedElement.parentId) {
        parsedElement.parentId = idMap.get(parsedElement.parentId) ?? parsedElement.parentId;
      }

      parsedElement.parentId = parsedElement.parentId ?? rootId;

      parsedElement.level = parsedElement.level ?? 1;

      parsedElement.data = parsedElement.data ?? {};

      if (parsedElement.blockId) {
        idMap.set(parsedElement.blockId, newBlockId);
      }

      parsedElement.blockId = newBlockId;
      parsedElement.textId = generateId();
    }

    return insertFragment(fragment);
  };

  return editor;
}
