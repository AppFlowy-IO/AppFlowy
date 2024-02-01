import { ReactEditor } from 'slate-react';
import {
  Editor,
  Element,
  Node,
  NodeEntry,
  Point,
  Range,
  Transforms,
  Location,
  Path,
  EditorBeforeOptions,
  Text,
} from 'slate';
import { LIST_TYPES, tabBackward, tabForward } from '$app/components/editor/command/tab';
import { isMarkActive, removeMarks, toggleMark } from '$app/components/editor/command/mark';
import {
  deleteFormula,
  insertFormula,
  isFormulaActive,
  unwrapFormula,
  updateFormula,
} from '$app/components/editor/command/formula';
import {
  EditorInlineNodeType,
  EditorNodeType,
  CalloutNode,
  Mention,
  TodoListNode,
  ToggleListNode,
  inlineNodeTypes,
  FormulaNode,
} from '$app/application/document/document.types';
import cloneDeep from 'lodash-es/cloneDeep';
import { generateId } from '$app/components/editor/provider/utils/convert';
import { YjsEditor } from '@slate-yjs/core';

export const EmbedTypes: string[] = [
  EditorNodeType.DividerBlock,
  EditorNodeType.EquationBlock,
  EditorNodeType.GridBlock,
];

export const CustomEditor = {
  getBlock: (editor: ReactEditor, at?: Location): NodeEntry<Element> | undefined => {
    return Editor.above(editor, {
      at,
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
    });
  },

  isInlineNode: (editor: ReactEditor, point: Point): boolean => {
    return Boolean(
      editor.above({
        at: point,
        match: (n) => {
          return !Editor.isEditor(n) && Element.isElement(n) && inlineNodeTypes.includes(n.type as EditorInlineNodeType);
        },
      })
    );
  },

  beforeIsInlineNode: (editor: ReactEditor, at: Location, opts?: EditorBeforeOptions): boolean => {
    const beforePoint = Editor.before(editor, at, opts);

    if (!beforePoint) return false;
    return CustomEditor.isInlineNode(editor, beforePoint);
  },

  afterIsInlineNode: (editor: ReactEditor, at: Location, opts?: EditorBeforeOptions): boolean => {
    const afterPoint = Editor.after(editor, at, opts);

    if (!afterPoint) return false;
    return CustomEditor.isInlineNode(editor, afterPoint);
  },
  blockEqual: (editor: ReactEditor, point: Point, anotherPoint: Point) => {
    const match = CustomEditor.getBlock(editor, point);
    const anotherMatch = CustomEditor.getBlock(editor, anotherPoint);

    if (!match || !anotherMatch) return false;

    const [node] = match;
    const [anotherNode] = anotherMatch;

    return node === anotherNode;
  },

  /**
   * turn the current block to a new block
   * 1. clone the current block to a new block
   * 2. lift the children of the current block if the current block doesn't allow has children
   * 3. remove the old block
   * 4. insert the new block
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

    Object.assign(cloneNode, newProperties);

    const isEmbed = editor.isEmbed(cloneNode);

    if (isEmbed) {
      editor.splitNodes({
        always: true,
      });
      cloneNode.children = [];

      Transforms.removeNodes(editor, {
        at: path,
      });
      Transforms.insertNodes(editor, cloneNode, { at: path });
      return;
    }

    const isListType = LIST_TYPES.includes(cloneNode.type as EditorNodeType);

    // if node doesn't allow has children, lift the children before insert the new node and remove the old node
    if (!isListType) {
      const [textNode, ...children] = cloneNode.children;

      const length = children.length;

      for (let i = 0; i < length; i++) {
        editor.liftNodes({
          at: [...path, length - i],
        });
      }

      cloneNode.children = [textNode];
    }

    Transforms.removeNodes(editor, {
      at: path,
    });

    Transforms.insertNodes(editor, cloneNode, { at: path });
    if (selection) {
      editor.select(selection);
    }
  },
  tabForward,
  tabBackward,
  toggleMark,
  removeMarks,
  isMarkActive,
  isFormulaActive,
  insertFormula,
  updateFormula,
  deleteFormula,
  toggleFormula: (editor: ReactEditor) => {
    if (isFormulaActive(editor)) {
      unwrapFormula(editor);
    } else {
      insertFormula(editor);
    }
  },

  isBlockActive(editor: ReactEditor, format?: string) {
    const match = CustomEditor.getBlock(editor);

    if (match && format !== undefined) {
      return match[0].type === format;
    }

    return !!match;
  },

  toggleAlign(editor: ReactEditor, format: string) {
    const matchNodes = Array.from(
      Editor.nodes(editor, {
        // Note: we need to select the text node instead of the element node, otherwise the parent node will be selected
        match: (n) => Element.isElement(n) && n.type === EditorNodeType.Text,
      })
    );

    if (!matchNodes) return;

    matchNodes.forEach((match) => {
      const [, textPath] = match as NodeEntry<Element>;
      const [node] = editor.parent(textPath) as NodeEntry<
        Element & {
          data: {
            align?: string;
          };
        }
      >;
      const path = ReactEditor.findPath(editor, node);

      const data = (node.data as { align?: string }) || {};
      const newProperties = {
        data: {
          ...data,
          align: data.align === format ? undefined : format,
        },
      } as Partial<Element>;

      Transforms.setNodes(editor, newProperties, { at: path });
    });
  },

  getAlign(editor: ReactEditor) {
    const match = CustomEditor.getBlock(editor);

    if (!match) return undefined;

    const [node] = match as NodeEntry<Element>;

    return (node.data as { align?: string })?.align;
  },

  isInlineActive(editor: ReactEditor) {
    const [match] = editor.nodes({
      match: (n) => {
        return !Editor.isEditor(n) && Element.isElement(n) && inlineNodeTypes.includes(n.type as EditorInlineNodeType);
      },
    });

    return !!match;
  },

  isMentionActive(editor: ReactEditor) {
    const [match] = editor.nodes({
      match: (n) => {
        return !Editor.isEditor(n) && Element.isElement(n) && n.type === EditorInlineNodeType.Mention;
      },
    });

    return Boolean(match);
  },

  insertMention(editor: ReactEditor, mention: Mention) {
    const mentionElement = {
      type: EditorInlineNodeType.Mention,
      children: [{ text: '@' }],
      data: {
        ...mention,
      },
    };

    Transforms.insertNodes(editor, mentionElement, {
      select: true,
    });
  },

  toggleTodo(editor: ReactEditor, node: TodoListNode) {
    const checked = node.data.checked;
    const path = ReactEditor.findPath(editor, node);
    const data = node.data || {};
    const newProperties = {
      data: {
        ...data,
        checked: !checked,
      },
    } as Partial<Element>;

    Transforms.setNodes(editor, newProperties, { at: path });
  },

  toggleToggleList(editor: ReactEditor, node: ToggleListNode) {
    const collapsed = node.data.collapsed;
    const path = ReactEditor.findPath(editor, node);
    const data = node.data || {};
    const newProperties = {
      data: {
        ...data,
        collapsed: !collapsed,
      },
    } as Partial<Element>;

    const selectMatch = Editor.above(editor, {
      match: (n) => Element.isElement(n) && n.blockId !== undefined,
    });

    Transforms.setNodes(editor, newProperties, { at: path });

    if (selectMatch) {
      const [selectNode] = selectMatch;
      const selectNodePath = ReactEditor.findPath(editor, selectNode);

      if (Path.isAncestor(path, selectNodePath)) {
        editor.select(path);
        editor.collapse({
          edge: 'start',
        });
      }
    }
  },

  setCalloutIcon(editor: ReactEditor, node: CalloutNode, newIcon: string) {
    const path = ReactEditor.findPath(editor, node);
    const data = node.data || {};
    const newProperties = {
      data: {
        ...data,
        icon: newIcon,
      },
    } as Partial<Element>;

    Transforms.setNodes(editor, newProperties, { at: path });
  },

  setMathEquationBlockFormula(editor: ReactEditor, node: Element, newFormula: string) {
    const path = ReactEditor.findPath(editor, node);
    const data = node.data || {};
    const newProperties = {
      data: {
        ...data,
        formula: newFormula,
      },
    } as Partial<Element>;

    Transforms.setNodes(editor, newProperties, { at: path });
  },

  setGridBlockViewId(editor: ReactEditor, node: Element, newViewId: string) {
    const path = ReactEditor.findPath(editor, node);
    const data = node.data || {};
    const newProperties = {
      data: {
        ...data,
        viewId: newViewId,
      },
    } as Partial<Element>;

    Transforms.setNodes(editor, newProperties, { at: path });
  },

  cloneBlock(editor: ReactEditor, block: Element): Element {
    const cloneNode: Element = {
      ...cloneDeep(block),
      blockId: generateId(),
      type: block.type === EditorNodeType.Page ? EditorNodeType.Paragraph : block.type,
      children: [],
    };
    const isEmbed = editor.isEmbed(cloneNode);

    if (isEmbed) {
      return cloneNode;
    }

    const [firstTextNode, ...children] = block.children as Element[];

    const textNode =
      firstTextNode && firstTextNode.type === EditorNodeType.Text
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

    const nextPath = Path.next(path);

    Transforms.insertNodes(editor, cloneNode, { at: nextPath });
    return cloneNode;
  },

  deleteNode(editor: ReactEditor, node: Node) {
    const path = ReactEditor.findPath(editor, node);

    Transforms.removeNodes(editor, {
      at: path,
    });
    editor.collapse({
      edge: 'start',
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

  insertEmptyLine: (editor: ReactEditor & YjsEditor, path: Path) => {
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
        at: path,
      }
    );
    ReactEditor.focus(editor);
    Transforms.move(editor);
  },

  insertEmptyLineAtEnd: (editor: ReactEditor & YjsEditor) => {
    CustomEditor.insertEmptyLine(editor, [editor.children.length]);
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

    const nodeData = node.data || {};
    const newProperties = {
      data: {
        ...nodeData,
        ...data,
      },
    } as Partial<Element>;

    Transforms.setNodes(editor, newProperties, { at: path });
    editor.select(path);
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

  getNodeTextContent(node: Node): string {
    if (Element.isElement(node) && node.type === EditorInlineNodeType.Formula) {
      return (node as FormulaNode).data || '';
    }

    if (Text.isText(node)) {
      return node.text || '';
    }

    return node.children.map((n) => CustomEditor.getNodeTextContent(n)).join('');
  },

  isEmbedNode(node: Element): boolean {
    return EmbedTypes.includes(node.type);
  },
};
