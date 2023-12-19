import { ReactEditor } from 'slate-react';
import { Editor, Element, Node, NodeEntry, Transforms } from 'slate';
import { LIST_TYPES, tabBackward, tabForward } from '$app/components/editor/command/tab';
import { isMarkActive, toggleMark } from '$app/components/editor/command/mark';
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
  turnToBlock: (editor: ReactEditor, newProperties: Partial<Element>) => {
    const selection = editor.selection;

    if (!selection) return;
    const [match] = Editor.nodes(editor, {
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined && n.type !== undefined,
    });

    if (!match) return;

    const [node, path] = match as NodeEntry<Element>;

    const parentId = node.parentId;
    const cloneNode = {
      ...cloneDeep(node),
      blockId: generateId(),
      textId: generateId(),
      type: newProperties.type || EditorNodeType.Paragraph,
      data: newProperties.data || {},
    };
    const isListType = LIST_TYPES.includes(cloneNode.type as EditorNodeType);
    const extendId = isListType ? cloneNode.blockId : parentId;
    const subordinates = CustomEditor.findNodeSubordinate(editor, node);

    Transforms.insertNodes(editor, cloneNode, { at: [path[0] + 1] });

    subordinates.forEach((subordinate) => {
      const subordinatePath = ReactEditor.findPath(editor, subordinate);
      const level = subordinate.level ?? 2;

      const newProperties = {
        level: isListType ? level : level - 1,
      };

      if (subordinate.parentId === node.blockId) {
        Object.assign(newProperties, {
          parentId: extendId,
        });
      }

      Transforms.setNodes(editor, newProperties, {
        at: [subordinatePath[0] + 1],
      });
    });

    Transforms.removeNodes(editor, {
      at: path,
    });

    Transforms.select(editor, selection);
  },
  tabForward,
  tabBackward,
  toggleMark,
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
    const [match] = Editor.nodes(editor, {
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined && n.type !== undefined,
    });

    if (format !== undefined) {
      return match && (match[0] as Element).type === format;
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

  splitToParagraph(editor: ReactEditor) {
    Transforms.splitNodes(editor, { always: true });
    Transforms.setNodes(editor, { type: EditorNodeType.Paragraph });
  },

  findParentNode(editor: ReactEditor, node: Element) {
    const parentId = node.parentId;

    if (!parentId) return null;

    return editor.children.find((child) => (child as Element).blockId === parentId) as Element;
  },

  findNodeSubordinate(editor: ReactEditor, node: Element) {
    const index = editor.children.findIndex((child) => (child as Element).blockId === node.blockId);

    const level = node.level ?? 1;
    const subordinateNodes: Element[] = [];

    if (index === editor.children.length - 1) return subordinateNodes;

    for (let i = index + 1; i < editor.children.length; i++) {
      const nextNode = editor.children[i] as Element & { level: number };

      if (nextNode.level > level) {
        subordinateNodes.push(nextNode);
      } else {
        break;
      }
    }

    return subordinateNodes;
  },

  findNextNode(editor: ReactEditor, node: Element, level: number) {
    const index = editor.children.findIndex((child) => (child as Element).blockId === node.blockId);
    let nextIndex = -1;

    if (index === editor.children.length - 1) return null;

    for (let i = index + 1; i < editor.children.length; i++) {
      const nextNode = editor.children[i] as Element & { level: number };

      if (nextNode.level === level) {
        nextIndex = i;
        break;
      }

      if (nextNode.level < level) break;
    }

    const nextNode = editor.children[nextIndex] as Element & { level: number };

    return nextNode;
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
    if (!node.level) return;
    const collapsed = !node.data.collapsed;

    const path = ReactEditor.findPath(editor, node);
    const newProperties = {
      data: {
        collapsed,
      },
    } as Partial<Element>;

    Transforms.select(editor, path);
    Transforms.collapse(editor, { edge: 'end' });
    Transforms.setNodes(editor, newProperties, { at: path });

    // hide or show the children
    const index = path[0];

    if (index === editor.children.length - 1) return;

    for (let i = index + 1; i < editor.children.length; i++) {
      const nextNode = editor.children[i] as Element & { level: number };

      if (nextNode.level === node.level) break;
      if (nextNode.level > node.level) {
        const nextPath = ReactEditor.findPath(editor, nextNode);
        const nextProperties = {
          isHidden: collapsed,
        } as Partial<Element>;

        Transforms.setNodes(editor, nextProperties, { at: nextPath });
      }
    }
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

  findNodeChildren(editor: ReactEditor, node: Node) {
    const nodeId = (node as Element).blockId;

    return editor.children.filter((child) => (child as Element).parentId === nodeId) as Element[];
  },

  duplicateNode(editor: ReactEditor, node: Node) {
    const children = CustomEditor.findNodeChildren(editor, node);
    const newBlockId = generateId();
    const newTextId = generateId();
    const cloneNode = {
      ...cloneDeep(node),
      blockId: newBlockId,
      textId: newTextId,
    };

    const cloneChildren = children.map((child) => {
      const childBlockId = generateId();
      const childTextId = generateId();

      return {
        ...cloneDeep(child),
        blockId: childBlockId,
        textId: childTextId,
        parentId: newBlockId,
      };
    });

    const path = ReactEditor.findPath(editor, node);
    const endPath = children.length ? ReactEditor.findPath(editor, children[children.length - 1]) : null;

    Transforms.insertNodes(editor, [cloneNode, ...cloneChildren], { at: [endPath ? endPath[0] + 1 : path[0] + 1] });
    Transforms.move(editor);
  },

  deleteNode(editor: ReactEditor, node: Node) {
    const children = CustomEditor.findNodeChildren(editor, node);
    const path = ReactEditor.findPath(editor, node);
    const endPath = children.length ? ReactEditor.findPath(editor, children[children.length - 1]) : null;

    Transforms.removeNodes(editor, {
      at: {
        anchor: { path, offset: 0 },
        focus: { path: endPath ?? path, offset: 0 },
      },
    });

    Transforms.move(editor);
  },

  getBlockType: (editor: ReactEditor) => {
    const [match] = Editor.nodes(editor, {
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined && n.type !== undefined,
    });

    if (!match) return null;

    const [node] = match as NodeEntry<Element>;

    return node.type as EditorNodeType;
  },

  isGridBlock: (editor: ReactEditor) => {
    return CustomEditor.getBlockType(editor) === EditorNodeType.GridBlock;
  },

  isCodeBlock: (editor: ReactEditor) => {
    return CustomEditor.getBlockType(editor) === EditorNodeType.CodeBlock;
  },

  insertEmptyLineAtEnd: (editor: ReactEditor & YjsEditor) => {
    editor.insertNode(
      {
        type: EditorNodeType.Paragraph,
        level: 1,
        data: {},
        blockId: generateId(),
        textId: generateId(),
        parentId: editor.sharedRoot.getAttribute('blockId'),
        children: [{ text: '' }],
      },
      {
        select: true,
        at: [editor.children.length],
      }
    );
    ReactEditor.focus(editor);
    Transforms.move(editor);
  },

  insertLineAtStart: (editor: ReactEditor & YjsEditor, node: Element) => {
    const blockId = generateId();
    const parentId = editor.sharedRoot.getAttribute('blockId');

    ReactEditor.focus(editor);
    editor.insertNode(
      {
        ...node,
        blockId,
        parentId,
        textId: generateId(),
        level: 1,
      },
      {
        at: [0],
      }
    );

    editor.select({
      anchor: {
        path: [0, 0],
        offset: 0,
      },
      focus: {
        path: [0, 0],
        offset: 0,
      },
    });
  },
};
