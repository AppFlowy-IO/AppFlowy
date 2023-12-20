import { ReactEditor } from 'slate-react';
import { Editor, Element, NodeEntry, Node, Transforms, Point, Path } from 'slate';
import { CustomEditor } from '$app/components/editor/command';
import { YjsEditor } from '@slate-yjs/core';
import { EditorNodeType } from '$app/application/document/document.types';

export function withMergeNodes(editor: ReactEditor) {
  const { mergeNodes, removeNodes } = editor;

  editor.removeNodes = (...args) => {
    const isDeleteRoot = args.some((arg) => {
      return (
        arg?.at &&
        (arg.at as Path).length === 1 &&
        (arg.at as Path)[0] === 0 &&
        (editor.children[0] as Element).type === EditorNodeType.Page
      );
    });

    // the root node cannot be deleted
    if (isDeleteRoot) return;
    removeNodes(...args);
  };

  editor.mergeNodes = (...args) => {
    const isBlock = (n: Node) =>
      !Editor.isEditor(n) && Element.isElement(n) && n.type !== undefined && n.level !== undefined;

    const [merged] = Editor.nodes(editor, {
      match: isBlock,
    });

    if (!merged) {
      mergeNodes(...args);
      return;
    }

    const [mergedNode, path] = merged as NodeEntry<Element & { level: number; blockId: string }>;
    const root = editor.children[0] as Element & {
      blockId: string;
      level: number;
    };
    const selection = editor.selection;
    const start = Editor.start(editor, path);

    if (
      root.type === EditorNodeType.Page &&
      mergedNode.type === EditorNodeType.Paragraph &&
      selection &&
      Point.equals(selection.anchor, start) &&
      path[0] === 1
    ) {
      if (Editor.isEmpty(editor, root)) {
        const text = Editor.string(editor, path);

        editor.select([0]);
        editor.insertText(text);
        editor.removeNodes({ at: path });
        // move children to root
        moveNodes(editor, 1, root.blockId, (n) => {
          return n.parentId === mergedNode.blockId;
        });

        return;
      }
    }

    const nextNode = editor.children[path[0] + 1] as Element & { level: number };

    mergeNodes(...args);

    if (!nextNode) {
      CustomEditor.insertEmptyLineAtEnd(editor as ReactEditor & YjsEditor);
      return;
    }

    if (mergedNode.blockId === nextNode.parentId) {
      // the node will be deleted when the node has no text
      if (mergedNode.children.length === 1 && 'text' in mergedNode.children[0] && mergedNode.children[0].text === '') {
        moveNodes(editor, root.level + 1, root.blockId, (n) => n.parentId === mergedNode.blockId);
      }

      return;
    }

    // check if the old node is removed
    const oldNodeRemoved = !editor.children.some((child) => (child as Element).blockId === nextNode.parentId);

    if (oldNodeRemoved) {
      // if the old node is removed, we need to move the children of the old node to the new node
      moveNodes(editor, mergedNode.level + 1, mergedNode.blockId, (n) => {
        return n.parentId === nextNode.parentId;
      });
    }
  };

  return editor;
}

function moveNodes(editor: ReactEditor, level: number, parentId: string, match: (n: Element) => boolean) {
  editor.children.forEach((child, index) => {
    if (match(child as Element)) {
      Transforms.setNodes(editor, { level, parentId }, { at: [index] });
    }
  });
}
