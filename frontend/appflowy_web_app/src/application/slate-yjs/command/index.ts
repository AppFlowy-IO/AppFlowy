import { LIST_BLOCK_TYPES } from '@/application/slate-yjs/command/const';
import { YjsEditor } from '@/application/slate-yjs/plugins/withYjs';
import { EditorMarkFormat } from '@/application/slate-yjs/types';
import { beforePasted, findSlateEntryByBlockId } from '@/application/slate-yjs/utils/slateUtils';

import {
  addBlock,
  dataStringTOJson,
  deepCopyBlock,
  deleteBlock,
  executeOperations,
  getAffectedBlocks,
  getBlock,
  getBlockEntry,
  getBlockIndex,
  getParent,
  getPreviousSiblingBlock,
  getSelectionOrThrow,
  getSelectionTexts,
  getSharedRoot,
  handleCollapsedBreakWithTxn,
  handleDeleteEntireDocumentWithTxn,
  handleLiftBlockOnBackspaceAndEnterWithTxn,
  handleMergeBlockBackwardWithTxn,
  handleMergeBlockForwardWithTxn,
  handleNonParagraphBlockBackspaceAndEnterWithTxn,
  handleRangeBreak,
  indentBlock,
  liftBlock,
  preventIndentNode,
  preventLiftNode,
  removeRangeWithTxn,
  turnToBlock,
  updateBlockParent,
} from '@/application/slate-yjs/utils/yjsOperations';
import {
  BlockData,
  BlockType,
  Mention,
  MentionType,
  TodoListBlockData,
  ToggleListBlockData,
  YjsEditorKey,
} from '@/application/types';
import { EditorInlineAttributes } from '@/slate-editor';
import { renderDate } from '@/utils/time';
import isEqual from 'lodash-es/isEqual';
import { BasePoint, BaseRange, Editor, Element, Node, NodeEntry, Path, Range, Text, Transforms } from 'slate';
import { ReactEditor } from 'slate-react';

export const CustomEditor = {
  // find entry from blockId
  getBlockEntry(editor: YjsEditor, blockId: string): NodeEntry<Element> | undefined {
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
  getBlockTextContent(node: Node, depth: number = Infinity): string {
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

  setBlockData<T = BlockData>(editor: YjsEditor, blockId: string, updateData: T, select?: boolean) {

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
  insertBreak(editor: YjsEditor, at?: BaseRange) {
    const sharedRoot = getSharedRoot(editor);
    const newAt = getSelectionOrThrow(editor, at);

    const isCollapsed = Range.isCollapsed(newAt);

    if (isCollapsed) {
      handleCollapsedBreakWithTxn(editor, sharedRoot, newAt);
    } else {
      handleRangeBreak(editor, sharedRoot, newAt);
    }

  },

  deleteBlockBackward(editor: YjsEditor, at?: BaseRange) {
    console.trace('deleteBlockBackward', editor.selection, at);

    const sharedRoot = getSharedRoot(editor);
    const newAt = getSelectionOrThrow(editor, at);

    const isCollapsed = Range.isCollapsed(newAt);

    if (isCollapsed) {
      const point = newAt.anchor;

      const blockEntry = getBlockEntry(editor, point);

      const [node, path] = blockEntry as NodeEntry<Element>;
      const block = getBlock(node.blockId as string, sharedRoot);
      const blockType = block.get(YjsEditorKey.block_type) as BlockType;
      const parent = getParent(node.blockId as string, sharedRoot);

      if (blockType !== BlockType.Paragraph && parent?.get(YjsEditorKey.block_type) === BlockType.QuoteBlock && LIST_BLOCK_TYPES.includes(blockType)) {
        handleNonParagraphBlockBackspaceAndEnterWithTxn(editor, sharedRoot, block, point);
        return;
      }

      if (path.length > 1 && handleLiftBlockOnBackspaceAndEnterWithTxn(editor, sharedRoot, block, point)) {
        return;
      }

      if (blockType !== BlockType.Paragraph) {
        handleNonParagraphBlockBackspaceAndEnterWithTxn(editor, sharedRoot, block, point);
        return;
      }

      handleMergeBlockBackwardWithTxn(editor, node, point);
    } else {

      Transforms.collapse(editor, { edge: 'start' });
      removeRangeWithTxn(editor, sharedRoot, newAt);
    }
  },

  deleteBlockForward(editor: YjsEditor, at?: BaseRange) {
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

  deleteEntireDocument(editor: YjsEditor) {
    handleDeleteEntireDocumentWithTxn(editor);
  },

  removeRange(editor: YjsEditor, at: BaseRange) {
    removeRangeWithTxn(editor, getSharedRoot(editor), at);
  },

  tabEvent(editor: YjsEditor, event: KeyboardEvent) {
    const type = event.shiftKey ? 'tabBackward' : 'tabForward';
    const sharedRoot = getSharedRoot(editor);
    const { selection } = editor;

    if (!selection) return;
    const [point, endPoint] = editor.edges(selection);
    const { middleBlocks, startBlock: node, endBlock: endNode } = getAffectedBlocks(editor, selection);

    if (type === 'tabBackward' && preventLiftNode(editor, node[0].blockId as string)) {
      return;
    }

    if (type === 'tabForward' && preventIndentNode(editor, node[0].blockId as string)) {
      return;
    }

    const startBlockPath = node[1];
    const endBlockPath = endNode[1];
    const startAtPath = point.path.slice(startBlockPath.length);
    const startAtOffset = point.offset;
    const isAncestor = Path.isAncestor(startBlockPath, endBlockPath);
    const endRelativeToStart = endBlockPath.slice(startBlockPath.length);

    const endAtPath = endPoint.path.slice(endBlockPath.length);
    const endAtOffset = endPoint.offset;
    let newStartBlockPath: Path = [];
    let newEndBlockPath: Path = [];

    const isSameBlock = node[0].blockId === endNode[0].blockId;

    editor.deselect();
    if (isSameBlock) {
      const block = getBlock(node[0].blockId as string, sharedRoot);
      let newBlockId: string | undefined;

      executeOperations(sharedRoot, [() => {
        newBlockId = type === 'tabForward' ? indentBlock(sharedRoot, block) : liftBlock(sharedRoot, block);
      }], type === 'tabForward' ? 'indentBlock' : 'liftBlock');

      if (!newBlockId) return;
      const newBlockEntry = findSlateEntryByBlockId(editor, newBlockId);

      newStartBlockPath = newBlockEntry[1];
      newEndBlockPath = newStartBlockPath;
    } else {
      const blocks = [node, ...middleBlocks, endNode] as NodeEntry<Element>[];
      const newBlockIds: string[] = [];

      blocks.forEach((entry, index) => {
        const blockId = entry[0].blockId as string;
        const block = getBlock(blockId, sharedRoot);

        if (!block) return;

        executeOperations(sharedRoot, [() => {
          const newBlockId = type === 'tabForward' ? indentBlock(sharedRoot, block) : liftBlock(sharedRoot, block, index);

          if (newBlockId) {
            newBlockIds.push(newBlockId);
          }
        }], type === 'tabForward' ? 'indentBlock' : 'liftBlock');
      });
      if (newBlockIds.length === 0) return;
      const newStartBlockEntry = findSlateEntryByBlockId(editor, newBlockIds[0]);
      const newEndBlockEntry = findSlateEntryByBlockId(editor, newBlockIds[newBlockIds.length - 1]);

      newStartBlockPath = newStartBlockEntry[1];
      newEndBlockPath = isAncestor ? [...newStartBlockPath, ...endRelativeToStart] : newEndBlockEntry[1];
    }

    const newStartPath = [...newStartBlockPath, ...startAtPath];
    const newEndPath = [...newEndBlockPath, ...endAtPath];

    Transforms.select(editor, {
      anchor: {
        path: newStartPath,
        offset: startAtOffset,
      },
      focus: {
        path: newEndPath,
        offset: endAtOffset,
      },
    });
  },

  toggleToggleList(editor: YjsEditor, blockId: string) {
    const sharedRoot = getSharedRoot(editor);
    const data = dataStringTOJson(getBlock(blockId, sharedRoot).get(YjsEditorKey.block_data)) as ToggleListBlockData;
    const { selection } = editor;

    if (selection && Range.isExpanded(selection)) {
      Transforms.collapse(editor, { edge: 'start' });
    }

    let selected = false;

    if (selection) {
      const point = Editor.start(editor, selection);

      const [node] = getBlockEntry(editor, point);

      selected = node.blockId !== blockId;
    }

    CustomEditor.setBlockData(editor, blockId, {
      collapsed: !data.collapsed,
    }, selected);
  },

  toggleTodoList(editor: YjsEditor, blockId: string, shiftKey: boolean) {
    const sharedRoot = getSharedRoot(editor);
    const block = getBlock(blockId, sharedRoot);
    const data = dataStringTOJson(block.get(YjsEditorKey.block_data)) as TodoListBlockData;
    const checked = data.checked;

    if (!shiftKey) {
      CustomEditor.setBlockData(editor, blockId, {
        checked: !checked,
      }, false);
      return;
    }

    const [, path] = findSlateEntryByBlockId(editor, blockId);
    const [start, end] = editor.edges(path);

    const toggleBlockNodes = Array.from(
      Editor.nodes(editor, {
        at: {
          anchor: start,
          focus: end,
        },
        match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.type === BlockType.TodoListBlock,
      }),
    ) as unknown as NodeEntry<Element>[];

    toggleBlockNodes.forEach(([node]) => {

      CustomEditor.setBlockData(editor, node.blockId as string, {
        checked: !checked,
      }, false);
    });
  },

  toggleMark(editor: ReactEditor, {
    key, value,
  }: {
    key: EditorMarkFormat, value: boolean | string
  }) {
    if (CustomEditor.isMarkActive(editor, key)) {
      CustomEditor.removeMark(editor, key);
    } else {
      CustomEditor.addMark(editor, {
        key, value,
      });
    }
  },

  getTextNodes(editor: ReactEditor) {
    return getSelectionTexts(editor);
  },

  addMark(editor: ReactEditor, {
    key, value,
  }: {
    key: EditorMarkFormat, value: boolean | string | Mention
  }) {
    editor.addMark(key, value);
  },

  removeMark(editor: ReactEditor, key: EditorMarkFormat) {
    editor.removeMark(key);
  },

  turnToBlock<T extends BlockData>(editor: YjsEditor, blockId: string, type: BlockType, data: T) {
    const operations: (() => void)[] = [];
    const sharedRoot = getSharedRoot(editor);
    const sourceBlock = getBlock(blockId, sharedRoot);
    const sourceType = sourceBlock.get(YjsEditorKey.block_type) as BlockType;
    const oldData = dataStringTOJson(sourceBlock.get(YjsEditorKey.block_data));

    if (sourceType === type && isEqual(oldData, data)) {
      return;
    }

    let newBlockId: string | undefined;

    operations.push(() => {
      newBlockId = turnToBlock(sharedRoot, sourceBlock, type, data);
    });

    executeOperations(sharedRoot, operations, 'turnToBlock');
    return newBlockId;
  },

  isBlockActive(editor: YjsEditor, type: BlockType) {
    try {
      const [node] = getBlockEntry(editor);

      return node.type === type;
    } catch (e) {
      return false;
    }
  },

  hasMark(editor: ReactEditor, key: string) {
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

  getAllMarks(editor: ReactEditor) {
    const selection = editor.selection;

    if (!selection) return [];

    const isExpanded = Range.isExpanded(selection);

    if (isExpanded) {
      const texts = getSelectionTexts(editor);

      return texts.map((node) => {
        const { text, ...attributes } = node;

        if (!text) return {};
        return attributes as EditorInlineAttributes;
      });
    }

    const marks = Editor.marks(editor) as EditorInlineAttributes;

    return [marks];
  },

  isMarkActive(editor: ReactEditor, key: string) {
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

  addChildBlock(editor: YjsEditor, blockId: string, type: BlockType, data: BlockData) {
    const sharedRoot = getSharedRoot(editor);
    const parent = getBlock(blockId, sharedRoot);

    if (!parent) {
      console.warn('Parent block not found');
      return;
    }

    const newBlockId = addBlock(editor, {
      ty: type,
      data,
    }, parent, 0);

    if (!newBlockId) {
      console.warn('Failed to add block');
      return;
    }

    try {
      const [, path] = findSlateEntryByBlockId(editor, newBlockId);

      if (path) {
        ReactEditor.focus(editor);
        const point = editor.start(path);

        Transforms.select(editor, point);
        return newBlockId;
      }
    } catch (e) {
      console.error(e);
    }
  },

  addBlock(editor: YjsEditor, blockId: string, direction: 'below' | 'above', type: BlockType, data: BlockData) {
    const parent = getParent(blockId, editor.sharedRoot);
    const index = getBlockIndex(blockId, editor.sharedRoot);

    if (!parent) return;

    const newBlockId = addBlock(editor, {
      ty: type,
      data,
    }, parent, direction === 'below' ? index + 1 : index);

    if (!newBlockId) {
      return;
    }

    try {
      const [, path] = findSlateEntryByBlockId(editor, newBlockId);

      if (path) {
        ReactEditor.focus(editor);
        const point = editor.start(path);

        Transforms.select(editor, point);
        return newBlockId;
      }
    } catch (e) {
      console.error(e);
    }
  },

  addBelowBlock(editor: YjsEditor, blockId: string, type: BlockType, data: BlockData) {
    return CustomEditor.addBlock(editor, blockId, 'below', type, data);
  },

  addAboveBlock(editor: YjsEditor, blockId: string, type: BlockType, data: BlockData) {
    return CustomEditor.addBlock(editor, blockId, 'above', type, data);
  },

  deleteBlock(editor: YjsEditor, blockId: string) {
    const sharedRoot = getSharedRoot(editor);
    const parent = getParent(blockId, sharedRoot);

    if (!parent) {
      console.warn('Parent block not found');
      return;
    }

    try {
      const prevBlockId = getPreviousSiblingBlock(sharedRoot, getBlock(blockId, sharedRoot));
      let point: BasePoint | undefined;

      if (!prevBlockId) {
        if (parent.get(YjsEditorKey.block_type) !== BlockType.Page) {
          const [, path] = findSlateEntryByBlockId(editor, parent.get(YjsEditorKey.block_id));

          point = editor.start(path);
        }
      } else {
        const [, path] = findSlateEntryByBlockId(editor, prevBlockId);

        point = editor.end(path);
      }

      if (point && ReactEditor.hasRange(editor, {
        anchor: point,
        focus: point,
      })) {
        Transforms.select(editor, point);
      } else {
        Transforms.deselect(editor);
      }

    } catch (e) {
      // do nothing
    }

    executeOperations(sharedRoot, [() => {
      deleteBlock(sharedRoot, blockId);
    }], 'deleteBlock');
    const children = editor.children;

    if (children.length === 0) {
      addBlock(editor, {
        ty: BlockType.Paragraph,
        data: {},
      }, parent, 0);
    }

    ReactEditor.focus(editor);
  },

  duplicateBlock(editor: YjsEditor, blockId: string, prevId?: string) {
    const sharedRoot = getSharedRoot(editor);
    const block = getBlock(blockId, sharedRoot);

    const parent = getParent(blockId, sharedRoot);
    const prevIndex = getBlockIndex(prevId || blockId, sharedRoot);

    if (!parent) {
      console.warn('Parent block not found');
      return;
    }

    let newBlockId: string | null = null;

    executeOperations(sharedRoot, [() => {
      newBlockId = deepCopyBlock(sharedRoot, block);

      if (!newBlockId) {
        console.warn('Copied block not found');
        return;
      }

      const copiedBlock = getBlock(newBlockId, sharedRoot);

      updateBlockParent(sharedRoot, copiedBlock, parent, prevIndex + 1);
    }], 'duplicateBlock');

    return newBlockId;
  },

  pastedText(editor: YjsEditor, text: string) {
    if (!beforePasted(editor))
      return;

    const point = editor.selection?.anchor as BasePoint;

    Transforms.insertNodes(editor, { text }, { at: point, select: true, voids: false });
  },

  highlight(editor: ReactEditor) {
    const selection = editor.selection;

    if (!selection) return;

    const [start, end] = Range.edges(selection);

    if (isEqual(start, end)) return;

    const marks = CustomEditor.getAllMarks(editor);

    marks.forEach((mark) => {
      if (mark[EditorMarkFormat.BgColor]) {
        CustomEditor.removeMark(editor, EditorMarkFormat.BgColor);
      } else {
        CustomEditor.addMark(editor, {
          key: EditorMarkFormat.BgColor,
          value: '#ffeb3b',
        });
      }
    });
  },
};
