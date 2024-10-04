import { YjsEditor } from '@/application/slate-yjs/plugins/withYjs';
import { EditorMarkFormat } from '@/application/slate-yjs/types';
import {
  dataStringTOJson,
  executeOperations,
  getBlock,
  getBlockEntry,
  getSelectionOrThrow,
  getSharedRoot,
  handleCollapsedBreakWithTxn,
  handleDeleteEntireDocumentWithTxn,
  handleMergeBlockBackwardWithTxn,
  handleNonParagraphBlockBackspaceWithTxn,
  handleRangeBreak,
  handleLiftBlockOnBackspaceWithTxn,
  handleMergeBlockForwardWithTxn,
  removeRangeWithTxn, handleIndentBlockWithTxn, handleLiftBlockOnTabWithTxn,
} from '@/application/slate-yjs/utils/yjsOperations';
import {
  BlockData,
  BlockType,
  InlineBlockType,
  Mention,
  MentionType, TodoListBlockData,
  ToggleListBlockData,
  YjsEditorKey,
} from '@/application/types';
import { FormulaNode } from '@/components/editor/editor.type';
import { renderDate } from '@/utils/time';
import { BasePoint, BaseRange, Editor, Element, Node, NodeEntry, Range, Text, Transforms } from 'slate';
import { ReactEditor } from 'slate-react';

export const CustomEditor = {
  findTextNode (editor: ReactEditor, path: number[]): NodeEntry<Element> {
    const [node] = editor.nodes({
      at: path,
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.textId !== undefined,
    });

    return node as NodeEntry<Element>;
  },
  // Get the text content of a block node, including the text content of its children and formula nodes
  getBlockTextContent (node: Node): string {
    if (Element.isElement(node)) {
      if (node.type === InlineBlockType.Formula) {
        return (node as FormulaNode).data || '';
      }

      if (node.type === InlineBlockType.Mention && (node.data as Mention)?.type === MentionType.Date) {
        const date = (node.data as Mention).date || '';
        const isUnix = date?.length === 10;

        return renderDate(date, 'MMM DD, YYYY', isUnix);
      }
    }

    if (Text.isText(node)) {
      if (node.formula) {
        return node.formula;
      }

      if (node.mention) {
        if (node.mention.type === MentionType.Date) {
          const date = node.mention.date || '';
          const isUnix = date?.length === 10;

          return renderDate(date, 'MMM DD, YYYY', isUnix);
        } else {
          const name = document.querySelector('[data-mention-id="' + node.mention.page_id + '"]')?.textContent || '';

          return name;
        }
      }

      return node.text || '';
    }

    return node.children.map((n) => CustomEditor.getBlockTextContent(n)).join('');
  },

  setBlockData<T = BlockData> (editor: YjsEditor, blockId: string, updateData: T, select?: boolean) {
    const readonly = editor.isElementReadOnly(editor);

    if (readonly) {
      return;
    }

    const block = getBlock(blockId, editor.sharedRoot);
    const oldData = dataStringTOJson(block.get(YjsEditorKey.block_data));
    const newData = {
      ...oldData,
      ...updateData,
    };
    const operations = [() => {
      block.set(YjsEditorKey.block_data, JSON.stringify(newData));
    }];
    const entry = Editor.above(editor, {
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId === blockId,
    });

    executeOperations(editor.sharedRoot, operations, 'setBlockData');

    if (!select) return;

    if (!entry) {
      Transforms.select(editor, Editor.start(editor, [0]));
      return;
    }

    const nodePath = entry[1];

    Transforms.select(editor, Editor.start(editor, nodePath));
  },
  // Insert break line at the specified path
  insertBreak (editor: YjsEditor, at?: BaseRange) {
    const sharedRoot = getSharedRoot(editor);
    const newAt = getSelectionOrThrow(editor, at);

    const isCollapsed = Range.isCollapsed(newAt);

    if (isCollapsed) {
      handleCollapsedBreakWithTxn(editor, sharedRoot, newAt);
    } else {
      handleRangeBreak(editor, sharedRoot, newAt);
    }

  },

  deleteBlockBackward (editor: YjsEditor, at?: BaseRange) {
    const sharedRoot = getSharedRoot(editor);
    const newAt = getSelectionOrThrow(editor, at);

    const isCollapsed = Range.isCollapsed(newAt);

    if (isCollapsed) {
      const point = newAt.anchor;

      const blockEntry = getBlockEntry(editor, point);

      const [node, path] = blockEntry as NodeEntry<Element>;
      const block = getBlock(node.blockId as string, sharedRoot);
      const blockType = block.get(YjsEditorKey.block_type) as BlockType;

      if (blockType !== BlockType.Paragraph) {
        handleNonParagraphBlockBackspaceWithTxn(sharedRoot, block);
        return;
      }

      if (path.length > 1 && handleLiftBlockOnBackspaceWithTxn(editor, sharedRoot, block, point)) {
        return;
      }

      handleMergeBlockBackwardWithTxn(editor, node, point);
    } else {
      Transforms.collapse(editor, { edge: 'start' });
      removeRangeWithTxn(editor, sharedRoot, newAt);
    }
  },

  deleteBlockForward (editor: YjsEditor, at?: BaseRange) {
    const sharedRoot = getSharedRoot(editor);
    const newAt = getSelectionOrThrow(editor, at);

    const isCollapsed = Range.isCollapsed(newAt);

    if (isCollapsed) {
      const point = newAt.anchor;

      const blockEntry = getBlockEntry(editor, point);

      const [node] = blockEntry as NodeEntry<Element>;

      handleMergeBlockForwardWithTxn(editor, node, point);
    } else {
      Transforms.collapse(editor, { edge: 'start' });
      removeRangeWithTxn(editor, sharedRoot, newAt);
    }
  },

  deleteEntireDocument (editor: YjsEditor) {
    handleDeleteEntireDocumentWithTxn(editor);
  },

  removeRange (editor: YjsEditor, at: BaseRange) {
    removeRangeWithTxn(editor, getSharedRoot(editor), at);
  },

  tabForward (editor: YjsEditor, point: BasePoint) {
    const sharedRoot = getSharedRoot(editor);
    const [node] = getBlockEntry(editor, point);

    const block = getBlock(node.blockId as string, sharedRoot);

    handleIndentBlockWithTxn(editor, sharedRoot, block, point);
  },

  tabBackward (editor: YjsEditor, point: BasePoint) {
    const sharedRoot = getSharedRoot(editor);
    const [node] = getBlockEntry(editor, point);

    const block = getBlock(node.blockId as string, sharedRoot);

    handleLiftBlockOnTabWithTxn(editor, sharedRoot, block, point);
  },

  toggleToggleList (editor: YjsEditor, blockId: string) {
    const sharedRoot = getSharedRoot(editor);
    const data = dataStringTOJson(getBlock(blockId, sharedRoot).get(YjsEditorKey.block_data)) as ToggleListBlockData;
    const { selection } = editor;

    if (!selection) return;

    if (Range.isExpanded(selection)) {
      Transforms.collapse(editor, { edge: 'start' });
    }

    const point = Editor.start(editor, selection);

    const [node] = getBlockEntry(editor, point);

    CustomEditor.setBlockData(editor, blockId, {
      collapsed: !data.collapsed,
    }, node.blockId !== blockId);
  },

  toggleTodoList (editor: YjsEditor, blockId: string) {
    const sharedRoot = getSharedRoot(editor);
    const data = dataStringTOJson(getBlock(blockId, sharedRoot).get(YjsEditorKey.block_data)) as TodoListBlockData;

    CustomEditor.setBlockData(editor, blockId, {
      checked: !data.checked,
    }, false);
  },

  toggleMark (editor: ReactEditor, {
    key, value,
  }: {
    key: EditorMarkFormat, value: boolean | string
  }) {
    editor.addMark(key, value);
  },
};
