import { ReactEditor } from 'slate-react';
import { Editor, Element, NodeEntry, Node, Transforms, Point, Path } from 'slate';
import { CustomEditor } from '$app/components/editor/command';
import { YjsEditor } from '@slate-yjs/core';
import { EditorNodeType } from '$app/application/document/document.types';

export function withMergeNodes(editor: ReactEditor) {
  const { mergeNodes, removeNodes } = editor;

  editor.removeNodes = (...args) => {
    const isDeleteRoot = args.some((arg) => {
      return arg?.at && (arg.at as Path).length === 1 && (arg.at as Path)[0] === 0;
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

    const [mergedNode, path] = merged as NodeEntry<Element & { level: number }>;
    const root = editor.children[0] as Element;
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

        return;
      }
    }

    mergeNodes(...args);

    const nextNode = editor.children[path[0] + 1] as Element & { level: number };

    if (!nextNode) {
      CustomEditor.insertEmptyLineAtEnd(editor as ReactEditor & YjsEditor);
      return;
    }

    if (mergedNode.blockId === nextNode.parentId) {
      return;
    }

    // check if the old node is removed
    const oldNodeRemoved = !editor.children.some((child) => (child as Element).blockId === nextNode.parentId);

    if (oldNodeRemoved) {
      // if the old node is removed, we need to move the children of the old node to the new node
      const oldNodeChildren = editor.children.filter((child) => (child as Element).parentId === nextNode.parentId);

      oldNodeChildren.forEach((child) => {
        const childPath = ReactEditor.findPath(editor, child);

        Transforms.setNodes(
          editor,
          { level: mergedNode.level + 1, parentId: mergedNode.blockId },
          { at: [childPath[0] - 1] }
        );
      });
    }
  };

  return editor;
}
