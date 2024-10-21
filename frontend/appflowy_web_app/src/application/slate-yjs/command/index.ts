import { YjsEditor } from '@/application/slate-yjs/plugins/withYjs';
import { EditorMarkFormat } from '@/application/slate-yjs/types';
import {
  dataStringTOJson,
  executeOperations,
  getBlock,
  getBlockEntry,
  getSelectionOrThrow, getSelectionTexts,
  getSharedRoot,
  handleCollapsedBreakWithTxn,
  handleDeleteEntireDocumentWithTxn,
  handleIndentBlockWithTxn,
  handleLiftBlockOnBackspaceAndEnterWithTxn,
  handleLiftBlockOnTabWithTxn,
  handleMergeBlockBackwardWithTxn,
  handleMergeBlockForwardWithTxn,
  handleNonParagraphBlockBackspaceAndEnterWithTxn,
  handleRangeBreak,
  removeRangeWithTxn,
  turnToBlock,
} from '@/application/slate-yjs/utils/yjsOperations';
import {
  BlockData,
  BlockType,
  MentionType,
  TodoListBlockData,
  ToggleListBlockData,
  YjsEditorKey,
} from '@/application/types';
import { renderDate } from '@/utils/time';
import isEqual from 'lodash-es/isEqual';
import { BasePoint, BaseRange, Editor, Element, Node, NodeEntry, Path, Range, Text, Transforms } from 'slate';
import { ReactEditor } from 'slate-react';

export const CustomEditor = {
  // find entry from blockId
  getBlockEntry (editor: YjsEditor, blockId: string): NodeEntry<Element> | undefined {
    const [entry] = editor.nodes({
      at: [],
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId === blockId,
    });

    if (!entry) {
      return;
    }

    return entry as NodeEntry<Element>;
  },
  // Get the text content of a block node, including the text content of its children and formula nodes
  getBlockTextContent (node: Node, depth: number = Infinity): string {
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

    if (depth <= 0) {
      return ''; // Prevent infinite recursion
    }

    return node.children
      .map((n) => CustomEditor.getBlockTextContent(n, depth - 1))
      .join('');
  },

  setBlockData<T = BlockData> (editor: YjsEditor, blockId: string, updateData: T, select?: boolean) {

    if (editor.readOnly) {
      return;
    }

    const block = getBlock(blockId, editor.sharedRoot);
    const oldData = dataStringTOJson(block.get(YjsEditorKey.block_data));
    const newData = {
      ...oldData,
      ...updateData,
    };

    const newProperties = {
      data: newData,
    } as Partial<Element>;
    const entry = CustomEditor.getBlockEntry(editor, blockId);

    if (!entry) {
      console.error('Block not found');
      return;
    }

    const [, path] = entry;
    let atChild = false;
    const { selection } = editor;

    if (selection && Path.isAncestor(path, selection.anchor.path)) {
      atChild = true;
    }

    Transforms.setNodes(editor, newProperties, { at: path });

    if (!select) return;

    if (atChild) {
      Transforms.select(editor, Editor.start(editor, path));
    }

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
        handleNonParagraphBlockBackspaceAndEnterWithTxn(sharedRoot, block);
        return;
      }

      if (path.length > 1 && handleLiftBlockOnBackspaceAndEnterWithTxn(editor, sharedRoot, block, point)) {
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
    if (CustomEditor.isMarkActive(editor, key)) {
      editor.removeMark(key);
    } else {
      editor.addMark(key, value);
    }
  },

  addMark (editor: ReactEditor, {
    key, value,
  }: {
    key: EditorMarkFormat, value: boolean | string
  }) {
    editor.addMark(key, value);
  },

  removeMark (editor: ReactEditor, key: EditorMarkFormat) {
    editor.removeMark(key);
  },

  turnToBlock<T extends BlockData> (editor: YjsEditor, blockId: string, type: BlockType, data: T) {
    const operations: (() => void)[] = [];
    const sharedRoot = getSharedRoot(editor);
    const sourceBlock = getBlock(blockId, sharedRoot);
    const sourceType = sourceBlock.get(YjsEditorKey.block_type) as BlockType;
    const oldData = dataStringTOJson(sourceBlock.get(YjsEditorKey.block_data));

    if (sourceType === type && isEqual(oldData, data)) {
      return;
    }

    operations.push(() => {
      turnToBlock(sharedRoot, sourceBlock, type, data);
    });

    executeOperations(sharedRoot, operations, 'turnToBlock');
  },

  isBlockActive (editor: YjsEditor, type: BlockType) {
    try {
      const [node] = getBlockEntry(editor);

      return node.type === type;
    } catch (e) {
      return false;
    }
  },

  hasMark (editor: ReactEditor, key: string) {
    const selection = editor.selection;

    if (!selection) return false;

    const isExpanded = Range.isExpanded(selection);

    if (isExpanded) {

      const texts = getSelectionTexts(editor);

      return texts.some((node) => {
        const { text, ...attributes } = node;

        if (!text) return true;
        return Boolean((attributes as Record<string, boolean | string>)[key]);
      });
    }

    const marks = Editor.marks(editor) as Record<string, string | boolean> | null;

    return marks ? !!marks[key] : false;
  },

  isMarkActive (editor: ReactEditor, key: string) {
    const selection = editor.selection;

    if (!selection) return false;

    const isExpanded = Range.isExpanded(selection);

    if (isExpanded) {

      const texts = getSelectionTexts(editor);

      return texts.every((node) => {
        const { text, ...attributes } = node;

        if (!text) return true;
        return Boolean((attributes as Record<string, boolean | string>)[key]);
      });
    }

    const marks = Editor.marks(editor) as Record<string, string | boolean> | null;

    return marks ? !!marks[key] : false;
  },
};
