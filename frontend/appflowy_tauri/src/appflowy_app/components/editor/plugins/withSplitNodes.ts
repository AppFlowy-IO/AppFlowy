import { ReactEditor } from 'slate-react';
import { Transforms, Editor, Element, NodeEntry, Path } from 'slate';
import { EditorNodeType, ToggleListNode } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';
import { generateId } from '$app/components/editor/provider/utils/convert';
import cloneDeep from 'lodash-es/cloneDeep';
import { SOFT_BREAK_TYPES } from '$app/components/editor/plugins/constants';

export function withSplitNodes(editor: ReactEditor) {
  const { splitNodes } = editor;

  editor.splitNodes = (...args) => {
    const isInsertBreak = args.length === 1 && JSON.stringify(args[0]) === JSON.stringify({ always: true });

    if (!isInsertBreak) {
      splitNodes(...args);
      return;
    }

    const match = CustomEditor.getBlock(editor);

    if (!match) {
      splitNodes(...args);
      return;
    }

    const [node, path] = match;
    const nodeType = node.type as EditorNodeType;

    const newBlockId = generateId();
    const newTextId = generateId();

    splitNodes(...args);

    const matchTextNode = editor.above({
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.type === EditorNodeType.Text,
    });

    if (!matchTextNode) return;
    const [textNode, textNodePath] = matchTextNode as NodeEntry<Element>;

    editor.removeNodes({
      at: textNodePath,
    });

    const newNodeType = [
      EditorNodeType.HeadingBlock,
      EditorNodeType.QuoteBlock,
      EditorNodeType.Page,
      ...SOFT_BREAK_TYPES,
    ].includes(node.type as EditorNodeType)
      ? EditorNodeType.Paragraph
      : node.type;

    const newNode: Element = {
      type: newNodeType,
      data: {},
      blockId: newBlockId,
      children: [
        {
          ...cloneDeep(textNode),
          textId: newTextId,
        },
      ],
    };
    let newNodePath;

    if (nodeType === EditorNodeType.ToggleListBlock) {
      const collapsed = (node as ToggleListNode).data.collapsed;

      if (!collapsed) {
        newNode.type = EditorNodeType.Paragraph;
        newNodePath = textNodePath;
      } else {
        newNode.type = EditorNodeType.ToggleListBlock;
        newNodePath = Path.next(path);
      }

      Transforms.insertNodes(editor, newNode, {
        at: newNodePath,
        select: true,
      });

      CustomEditor.removeMarks(editor);
      return;
    }

    newNodePath = textNodePath;

    Transforms.insertNodes(editor, newNode, {
      at: newNodePath,
    });

    editor.select(newNodePath);
    editor.collapse({
      edge: 'start',
    });

    editor.liftNodes({
      at: newNodePath,
    });

    CustomEditor.removeMarks(editor);
  };

  return editor;
}
