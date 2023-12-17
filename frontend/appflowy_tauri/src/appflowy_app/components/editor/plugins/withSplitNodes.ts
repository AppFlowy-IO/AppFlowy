import { ReactEditor } from 'slate-react';
import { Editor, Element, NodeEntry, Transforms } from 'slate';
import { EditorMarkFormat, EditorNodeType, markTypes, ToggleListNode } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';
import { BREAK_TO_PARAGRAPH_TYPES } from '$app/components/editor/plugins/constants';
import { generateId } from '$app/components/editor/provider/utils/convert';

export function withSplitNodes(editor: ReactEditor) {
  const { splitNodes } = editor;

  editor.splitNodes = (...args) => {
    const isInsertBreak = args.length === 1 && JSON.stringify(args[0]) === JSON.stringify({ always: true });

    if (!isInsertBreak) {
      splitNodes(...args);
      return;
    }

    // This is a workaround for the bug that the new paragraph will inherit the marks of the previous paragraph
    // remove all marks in current selection, otherwise the new paragraph will inherit the marks
    markTypes.forEach((markType) => {
      const isActive = CustomEditor.isMarkActive(editor, markType as EditorMarkFormat);

      if (isActive) {
        editor.removeMark(markType as EditorMarkFormat);
      }
    });

    const [match] = Editor.nodes(editor, {
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined && n.type !== undefined,
    });

    if (!match) {
      splitNodes(...args);
      return;
    }

    const [node, path] = match as NodeEntry<Element>;

    const newBlockId = generateId();
    const newTextId = generateId();

    const nodeType = node.type as EditorNodeType;

    // should be split to a new paragraph for the first child of the toggle list
    if (nodeType === EditorNodeType.ToggleListBlock) {
      const collapsed = (node as ToggleListNode).data.collapsed;
      const level = node.level ?? 1;
      const blockId = node.blockId as string;
      const parentId = node.parentId as string;

      // if the toggle list is collapsed, split to a new paragraph append to the children of the toggle list
      if (!collapsed) {
        splitNodes(...args);
        Transforms.setNodes(editor, {
          type: EditorNodeType.Paragraph,
          data: {},
          level: level + 1,
          blockId: newBlockId,
          parentId: blockId,
          textId: newTextId,
        });
      } else {
        // if the toggle list is not collapsed, split to a toggle list after the toggle list
        const nextNode = CustomEditor.findNextNode(editor, node, level);
        const nextIndex = nextNode ? ReactEditor.findPath(editor, nextNode)[0] : null;
        const index = path[0];

        splitNodes(...args);
        Transforms.setNodes(editor, { level, data: {}, blockId: newBlockId, parentId, textId: newTextId });
        if (nextIndex) {
          Transforms.moveNodes(editor, { at: [index + 1], to: [nextIndex] });
        }
      }

      return;
    }

    // should be split to another paragraph, eg: heading and quote
    if (BREAK_TO_PARAGRAPH_TYPES.includes(nodeType)) {
      splitNodes(...args);
      Transforms.setNodes(editor, {
        type: EditorNodeType.Paragraph,
        data: {},
        blockId: newBlockId,
        textId: newTextId,
      });
      return;
    }

    splitNodes(...args);

    Transforms.setNodes(editor, { blockId: newBlockId, data: {}, textId: newTextId });

    const children = CustomEditor.findNodeChildren(editor, node);

    children.forEach((child) => {
      const childPath = ReactEditor.findPath(editor, child);

      Transforms.setNodes(
        editor,
        {
          parentId: newBlockId,
        },
        {
          at: [childPath[0] + 1],
        }
      );
    });
  };

  return editor;
}
