import { ReactEditor } from 'slate-react';
import { Editor, Element, NodeEntry, Node, Transforms, Point } from 'slate';
import { CustomEditor } from '$app/components/editor/command';

export function withMergeNodes(editor: ReactEditor) {
  const { mergeNodes } = editor;

  // before merging nodes, check whether the node is a block and whether the selection is at the start of the block
  // if so, move the children of the node to the previous node
  editor.mergeNodes = (...args) => {
    const { selection } = editor;

    const isBlock = (n: Node) =>
      !Editor.isEditor(n) && Element.isElement(n) && n.type !== undefined && n.level !== undefined;

    const [match] = Editor.nodes(editor, {
      match: isBlock,
    });

    if (match && selection) {
      const [node, path] = match as NodeEntry<Element>;
      const start = Editor.start(editor, path);

      if (Point.equals(selection.anchor, start)) {
        const previous = Editor.previous(editor, { at: path });
        const [previousNode] = previous as NodeEntry<Element>;
        const previousLevel = previousNode.level ?? 1;

        const children = CustomEditor.findNodeChildren(editor, node);

        children.forEach((child) => {
          const childPath = ReactEditor.findPath(editor, child);

          Transforms.setNodes(editor, { level: previousLevel + 1, parentId: previousNode.blockId }, { at: childPath });
        });
      }
    }

    mergeNodes(...args);
  };

  return editor;
}
