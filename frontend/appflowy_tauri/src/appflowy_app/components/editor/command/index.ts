import { ReactEditor } from 'slate-react';
import { Editor, Element, Node, NodeEntry, Point, Range, Transforms, Location } from 'slate';
import { LIST_TYPES, tabBackward, tabForward } from '$app/components/editor/command/tab';
import { isMarkActive, removeMarks, toggleMark } from '$app/components/editor/command/mark';
import { insertFormula, isFormulaActive, unwrapFormula, updateFormula } from '$app/components/editor/command/formula';
import {
  EditorInlineNodeType,
  EditorNodeType,
  CalloutNode,
  Mention,
  TodoListNode,
  ToggleListNode,
} from '$app/application/document/document.types';
import cloneDeep from 'lodash-es/cloneDeep';
import { generateId } from '$app/components/editor/provider/utils/convert';
import { YjsEditor } from '@slate-yjs/core';

export const CustomEditor = {
  getBlock: (editor: ReactEditor, at?: Location): NodeEntry<Element> | undefined => {
    return Editor.above(editor, {
      at,
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
    });
  },

  /**
   * turn the current block to a new block
   * 1. clone the current block to a new block
   * 2. remove the current block
   * 3. insert the new block
   * 4. lift the children of the new block if the new block doesn't allow has children
   * @param editor
   * @param newProperties
   */
  turnToBlock: (editor: ReactEditor, newProperties: Partial<Element>) => {
    const selection = editor.selection;

    if (!selection) return;
    const match = CustomEditor.getBlock(editor);

    if (!match) return;

    const [node, path] = match as NodeEntry<Element>;

    const cloneNode = CustomEditor.cloneBlock(editor, node);

    Transforms.removeNodes(editor, {
      at: path,
    });

    Object.assign(cloneNode, newProperties);

    const [, ...children] = cloneNode.children;

    Transforms.insertNodes(editor, cloneNode, { at: path });

    const isListType = LIST_TYPES.includes(cloneNode.type as EditorNodeType);

    // if node doesn't allow has children, the children should be lifted
    if (!isListType) {
      const length = children.length;

      for (let i = 0; i < length; i++) {
        editor.liftNodes({
          at: [...path, length - i],
        });
      }
    }

    const isSelectable = editor.isSelectable(cloneNode);

    if (isSelectable) {
      Transforms.select(editor, selection);
    } else {
      Transforms.select(editor, path);
    }
  },
  tabForward,
  tabBackward,
  toggleMark,
  removeMarks,
  isMarkActive,
  isFormulaActive,
  updateFormula,
  toggleInlineElement: (editor: ReactEditor, format: EditorInlineNodeType) => {
    if (format === EditorInlineNodeType.Formula) {
      if (isFormulaActive(editor)) {
        unwrapFormula(editor);
      } else {
        insertFormula(editor);
      }
    }
  },

  isBlockActive(editor: ReactEditor, format?: string) {
    const match = CustomEditor.getBlock(editor);

    if (match && format !== undefined) {
      return match[0].type === format;
    }

    return !!match;
  },

  insertMention(editor: ReactEditor, mention: Mention) {
    const mentionElement = {
      type: EditorInlineNodeType.Mention,
      children: [{ text: '@' }],
      data: {
        ...mention,
      },
    };

    Transforms.insertNodes(editor, mentionElement);
    Transforms.move(editor);
  },

  toggleTodo(editor: ReactEditor, node: TodoListNode) {
    const checked = node.data.checked;
    const path = ReactEditor.findPath(editor, node);
    const newProperties = {
      data: {
        checked: !checked,
      },
    } as Partial<Element>;

    Transforms.setNodes(editor, newProperties, { at: path });
  },

  toggleToggleList(editor: ReactEditor, node: ToggleListNode) {
    const collapsed = node.data.collapsed;
    const path = ReactEditor.findPath(editor, node);
    const newProperties = {
      data: {
        collapsed: !collapsed,
      },
    } as Partial<Element>;

    Transforms.setNodes(editor, newProperties, { at: path });
    editor.select(path);
    editor.collapse({
      edge: 'start',
    });
  },

  setCalloutIcon(editor: ReactEditor, node: CalloutNode, newIcon: string) {
    const path = ReactEditor.findPath(editor, node);
    const newProperties = {
      data: {
        icon: newIcon,
      },
    } as Partial<Element>;

    Transforms.setNodes(editor, newProperties, { at: path });
  },

  setMathEquationBlockFormula(editor: ReactEditor, node: Element, newFormula: string) {
    const path = ReactEditor.findPath(editor, node);
    const newProperties = {
      data: {
        formula: newFormula,
      },
    } as Partial<Element>;

    Transforms.setNodes(editor, newProperties, { at: path });
  },

  setGridBlockViewId(editor: ReactEditor, node: Element, newViewId: string) {
    const path = ReactEditor.findPath(editor, node);
    const newProperties = {
      data: {
        viewId: newViewId,
      },
    } as Partial<Element>;

    Transforms.setNodes(editor, newProperties, { at: path });
  },

  cloneBlock(editor: ReactEditor, block: Element): Element {
    const cloneNode: Element = {
      ...cloneDeep(block),
      blockId: generateId(),
      children: [],
    };
    const [firstTextNode, ...children] = block.children as Element[];
    const isSelectable = editor.isSelectable(cloneNode);

    const textNode =
      firstTextNode && firstTextNode.type === EditorNodeType.Text && isSelectable
        ? {
            textId: generateId(),
            type: EditorNodeType.Text,
            children: cloneDeep(firstTextNode.children),
          }
        : undefined;

    if (textNode) {
      cloneNode.children.push(textNode);
    }

    const cloneChildren = children.map((child) => {
      return CustomEditor.cloneBlock(editor, child);
    });

    cloneNode.children.push(...cloneChildren);

    return cloneNode;
  },

  duplicateNode(editor: ReactEditor, node: Element) {
    const cloneNode = CustomEditor.cloneBlock(editor, node);

    const path = ReactEditor.findPath(editor, node);

    Transforms.insertNodes(editor, cloneNode, { at: path });
  },

  deleteNode(editor: ReactEditor, node: Node) {
    const path = ReactEditor.findPath(editor, node);

    Transforms.removeNodes(editor, {
      at: path,
    });
  },

  getBlockType: (editor: ReactEditor) => {
    const match = CustomEditor.getBlock(editor);

    if (!match) return null;

    const [node] = match as NodeEntry<Element>;

    return node.type as EditorNodeType;
  },

  selectionIncludeRoot: (editor: ReactEditor) => {
    const [match] = Editor.nodes(editor, {
      match: (n) => Element.isElement(n) && n.blockId !== undefined && n.type === EditorNodeType.Page,
    });

    return Boolean(match);
  },

  isCodeBlock: (editor: ReactEditor) => {
    return CustomEditor.getBlockType(editor) === EditorNodeType.CodeBlock;
  },

  insertEmptyLineAtEnd: (editor: ReactEditor & YjsEditor) => {
    editor.insertNode(
      {
        type: EditorNodeType.Paragraph,
        data: {},
        blockId: generateId(),
        children: [
          {
            type: EditorNodeType.Text,
            textId: generateId(),
            children: [
              {
                text: '',
              },
            ],
          },
        ],
      },
      {
        select: true,
        at: [editor.children.length],
      }
    );
    ReactEditor.focus(editor);
    Transforms.move(editor);
  },

  focusAtStartOfBlock(editor: ReactEditor) {
    const { selection } = editor;

    if (selection && Range.isCollapsed(selection)) {
      const match = CustomEditor.getBlock(editor);
      const [, path] = match as NodeEntry<Element>;
      const start = Editor.start(editor, path);

      return match && Point.equals(selection.anchor, start);
    }

    return false;
  },

  setBlockColor(
    editor: ReactEditor,
    node: Element,
    data: {
      font_color?: string;
      bg_color?: string;
    }
  ) {
    const path = ReactEditor.findPath(editor, node);
    const newProperties = {
      data,
    } as Partial<Element>;

    Transforms.setNodes(editor, newProperties, { at: path });
  },

  deleteAllText(editor: ReactEditor, node: Element) {
    const [textNode] = (node.children || []) as Element[];
    const hasTextNode = textNode && textNode.type === EditorNodeType.Text;

    if (!hasTextNode) return;
    const path = ReactEditor.findPath(editor, textNode);
    const textLength = editor.string(path).length;
    const start = Editor.start(editor, path);

    for (let i = 0; i < textLength; i++) {
      editor.select(start);
      editor.deleteForward('character');
    }
  },

  getNodeText: (editor: ReactEditor, node: Element) => {
    const [textNode] = (node.children || []) as Element[];
    const hasTextNode = textNode && textNode.type === EditorNodeType.Text;

    if (!hasTextNode) return '';

    const path = ReactEditor.findPath(editor, textNode);

    return editor.string(path);
  },

  isEmptyText: (editor: ReactEditor, node: Element) => {
    const [textNode] = (node.children || []) as Element[];
    const hasTextNode = textNode && textNode.type === EditorNodeType.Text;

    if (!hasTextNode) return false;

    return editor.isEmpty(textNode);
  },
};
