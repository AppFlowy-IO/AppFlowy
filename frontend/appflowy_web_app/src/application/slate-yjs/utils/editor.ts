import { CONTAINER_BLOCK_TYPES, isEmbedBlockTypes, TEXT_BLOCK_TYPES } from '@/application/slate-yjs/command/const';
import { findSlateEntryByBlockId } from '@/application/slate-yjs/utils/slateUtils';
import { BlockData, BlockType, ToggleListBlockData, YBlock, YjsEditorKey, YSharedRoot } from '@/application/types';
import { uniq } from 'lodash-es';
import Delta, { Op } from 'quill-delta';
import {
  BasePoint,
  BaseRange,
  Descendant,
  Editor,
  Element,
  Node,
  NodeEntry,
  Path,
  Point,
  Range,
  Text,
  Transforms,
} from 'slate';
import { ReactEditor } from 'slate-react';
import * as Y from 'yjs';
import { YjsEditor } from '../plugins/withYjs';
import {
  calculateOffsetRelativeToParent,
  calculatePointFromParentOffset,
  slatePointToRelativePosition,
} from './positions';
import {
  appendEmptyParagraph,
  assertDocExists,
  compatibleDataDeltaToYText,
  createBlock,
  dataStringTOJson,
  deleteBlock,
  executeOperations,
  extendNextSiblingsToToggleHeading,
  getBlock,
  getBlocks,
  getChildrenArray,
  getPageId,
  getParent,
  getSplitBlockOperations,
  getText,
  liftBlock,
  mergeBlockChildren,
  turnToBlock,
  updateBlockParent,
} from '@/application/slate-yjs/utils/yjs';

export function ensureBlockText(editor: YjsEditor) {
  const { selection } = editor;

  if (!selection) {
    return;
  }

  const sharedRoot = editor.sharedRoot;

  const [start, end] = editor.edges(selection);
  const startNodeEntry = getBlockEntry(editor, start);
  const [startNode] = startNodeEntry;
  const endNodeEntry = getBlockEntry(editor, end);
  const [endNode] = endNodeEntry;

  const startBlockId = startNode.blockId;

  const endBlockId = endNode.blockId;
  const startBlockType = startNode.type as BlockType;
  const endBlockType = endNode.type as BlockType;

  if (!startBlockId || !endBlockId) {
    return;
  }

  const compatibleBlocks: string[] = [];

  if (!isEmbedBlockTypes(startBlockType)) {
    compatibleBlocks.push(startBlockId);
  }

  if (!isEmbedBlockTypes(endBlockType)) {
    compatibleBlocks.push(endBlockId);
  }

  uniq(compatibleBlocks).forEach((blockId) => {
    const block = getBlock(blockId, sharedRoot);
    const textId = block.get(YjsEditorKey.block_external_id);

    if (!textId || !getText(textId, sharedRoot)) {
      const data = dataStringTOJson(block.get(YjsEditorKey.block_data)) as BlockData;

      compatibleDataDeltaToYText(sharedRoot, data.delta || [], blockId);
    }
  });
}

export function handleCollapsedBreakWithTxn(editor: YjsEditor, sharedRoot: YSharedRoot, at: BaseRange) {
  const { startBlock, startOffset } = getBreakInfo(editor, sharedRoot, at);
  const [blockNode, path] = startBlock;
  const blockId = blockNode.blockId as string;
  const block = getBlock(blockId, sharedRoot);

  if (!block) {
    throw new Error('Block not found');
  }

  const blockType = block.get(YjsEditorKey.block_type);
  const textId = block.get(YjsEditorKey.block_external_id);
  let yText = getText(textId, sharedRoot);

  if (!yText && !isEmbedBlockTypes(blockType)) {
    const data = blockNode.data as BlockData;
    const delta = new Delta(data.delta || []);

    yText = compatibleDataDeltaToYText(sharedRoot, delta.ops, blockId);

  }

  if (yText.length === 0) {
    const point = Editor.start(editor, at);

    const parent = getParent(blockId, sharedRoot);
    const parentType = parent?.get(YjsEditorKey.block_type);

    if (blockType !== BlockType.Paragraph && parentType && [BlockType.QuoteBlock, BlockType.CalloutBlock].includes(parentType)) {
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

  }

  const { operations, select } = getSplitBlockOperations(sharedRoot, block, startOffset);

  executeOperations(sharedRoot, operations, 'insertBreak');

  if (select) {
    moveToNextLine(editor, block, at, blockId);
  } else {
    Transforms.select(editor, Editor.start(editor, at));
  }

}

export function removeRangeWithTxn(editor: YjsEditor, sharedRoot: YSharedRoot, range: Range) {
  const { startBlock, endBlock, middleBlocks, startRange, endRange } = getAffectedBlocks(editor, range);
  const operations: (() => void)[] = [];
  const isSameBlock = startBlock[0].blockId === endBlock[0].blockId;

  console.log('startBlock', { startBlock, startRange });
  operations.push(() => {
    deleteSlateRangeInBlock(sharedRoot, editor, startBlock[0], startRange);
    if (!isSameBlock) {
      deleteSlateRangeInBlock(sharedRoot, editor, endBlock[0], endRange);
      mergeBlocks(sharedRoot, endBlock[0], startBlock[0]);

      middleBlocks.forEach((block) => {
        deleteBlock(sharedRoot, block[0].blockId as string);
      });
    }
  });
  Transforms.collapse(editor, { edge: 'start' });
  executeOperations(sharedRoot, operations, 'removeRange');

}

export function handleRangeBreak(editor: YjsEditor, sharedRoot: YSharedRoot, range: Range) {
  removeRangeWithTxn(editor, sharedRoot, range);

  const selection = editor.selection;

  if (!selection) return;

  handleCollapsedBreakWithTxn(editor, sharedRoot, selection);
}

function moveToNextLine(editor: Editor, block: YBlock, at: BaseRange, blockId: string) {
  const { selection } = editor;

  if (!selection) return;

  const { anchor, focus } = selection;

  if (!Node.has(editor, anchor.path) || !Node.has(editor, focus.path)) {
    Transforms.select(editor, Editor.start(editor, at));
    Transforms.move(editor, { distance: 1, unit: 'line' });
    return;
  }

  const blockType = block.get(YjsEditorKey.block_type);
  const isToggleListBlock = blockType === BlockType.ToggleListBlock;

  if (isToggleListBlock) {
    const blockData = dataStringTOJson(block.get(YjsEditorKey.block_data)) as ToggleListBlockData;
    const isCollapsed = blockData.collapsed;

    if (isCollapsed) {
      const nextBlockPath = getNextSiblingBlockPath(editor, blockId);

      if (nextBlockPath) {
        Transforms.select(editor, Editor.start(editor, nextBlockPath));
      } else {
        Transforms.select(editor, Editor.start(editor, at));
      }

      return;
    }
  }

  Transforms.move(editor, { distance: 1, unit: 'line' });
}

export function getNextSiblingBlockPath(editor: Editor, blockId: string) {
  const [blockSlateNode] = editor.nodes({
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId === blockId,
  });

  if (!blockSlateNode) {
    return;
  }

  const blockPath = blockSlateNode[1];
  const blockParentPath = blockPath.slice(0, -1);
  const index = blockPath[blockPath.length - 1];
  const nextPath = [...blockParentPath, index + 1];

  if (!nextPath || !Node.has(editor, nextPath)) {
    return;
  }

  return nextPath;
}

export function getBlockTextRange(editor: YjsEditor, entry: NodeEntry<Element>) {
  const [node, path] = entry;
  const textId = TEXT_BLOCK_TYPES.includes(node.type as BlockType) ? (node.children[0] as Element)?.textId : null;

  const start = Editor.start(editor, path);

  if (!textId) {
    return [start, editor.end(path)];
  }

  return [start, Editor.end(editor, [...path, 0])];
}

export function getAffectedBlocks(editor: YjsEditor, range: Range): {
  startBlock: NodeEntry<Element>;
  endBlock: NodeEntry<Element>;
  middleBlocks: NodeEntry<Element>[];
  startRange: BaseRange;
  endRange: BaseRange;
} {
  const [start, end] = Range.edges(range);

  const startBlock = Editor.above(editor, {
    at: start,
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
  }) as NodeEntry<Element>;

  const endBlock = Editor.above(editor, {
    at: end,
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
  }) as NodeEntry<Element>;

  let startRange = range;
  let endRange = range;

  const middleBlocks: NodeEntry<Element>[] = [];

  const isSameBlock = startBlock[0].blockId === endBlock[0].blockId;

  if (!isSameBlock) {
    for (const entry of Editor.nodes(editor, {
      at: range,
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined && n.blockId !== startBlock[0].blockId && n.blockId !== endBlock[0].blockId,
    })) {
      const [, path] = entry as NodeEntry<Element>;
      const isAncestorOfStart = Path.isAncestor(path, startBlock[1]);

      if (!isAncestorOfStart) {
        middleBlocks.push(entry as NodeEntry<Element>);
      }
    }

    startRange = {
      anchor: start,
      focus: getBlockTextRange(editor, startBlock)[1],
    };
    endRange = {
      anchor: Editor.start(editor, endBlock[1]),
      focus: end,
    };
  }

  return { startBlock, endBlock, middleBlocks, startRange, endRange };
}

function getTextIdFromSlateNode(node: Element) {
  return node.textId ?? (node.children[0] as Element).textId;
}

export function deleteSlateRangeInBlock(sharedRoot: YSharedRoot, editor: Editor, block: Element, range: BaseRange) {
  const [start, end] = Editor.edges(editor, range);

  const relativeOffset = slatePointToRelativePosition(sharedRoot, editor, start);
  const startPos = Y.createAbsolutePositionFromRelativePosition(relativeOffset.point, assertDocExists(sharedRoot));
  const endRelativeOffset = slatePointToRelativePosition(sharedRoot, editor, end);
  const endPos = Y.createAbsolutePositionFromRelativePosition(endRelativeOffset.point, assertDocExists(sharedRoot));

  if (!startPos || !endPos) {
    throw new Error('Unable to create absolute position');
  }

  deleteRangeInBlock(sharedRoot, block, startPos.index, endPos.index);
}

export function deleteRangeInBlock(
  sharedRoot: YSharedRoot,
  block: Element,
  start: number,
  end: number,
) {
  const textId = getTextIdFromSlateNode(block);

  if (textId) {
    const yText = getText(textId, sharedRoot);

    yText.delete(start, end - start);
  }
}

export function mergeBlocks(
  sharedRoot: YSharedRoot,
  sourceBlock: Element,
  targetBlock: Element,
) {
  const sourceTextId = getTextIdFromSlateNode(sourceBlock);
  const targetTextId = getTextIdFromSlateNode(targetBlock);

  if (!sourceTextId || !targetTextId) {
    return;
  }

  const sourceYText = getText(sourceTextId, sharedRoot);
  const targetYText = getText(targetTextId, sharedRoot);

  const sourceOps = sourceYText.toDelta() as Op[];

  sourceOps.forEach((op) => {
    if (op.insert && typeof op.insert === 'string') {
      targetYText.insert(targetYText.length, op.insert);
    }
  });

  const sourceBlockId = sourceBlock.blockId as string;
  const targetBlockId = targetBlock.blockId as string;

  mergeBlockChildren(sharedRoot, getBlock(sourceBlockId, sharedRoot), getBlock(targetBlockId, sharedRoot));
  deleteBlock(sharedRoot, sourceBlock.blockId as string);
}

export function getBreakInfo(editor: YjsEditor, sharedRoot: YSharedRoot, at: BaseRange) {
  const startPoint = Editor.start(editor, at);
  const doc = assertDocExists(sharedRoot);

  const startRelativeRange = slatePointToRelativePosition(sharedRoot, editor, startPoint);
  const startTextId = getTextIdFromSlateNode(startRelativeRange.entry[0]);

  if (!startTextId) {
    throw new Error('Text id not found');
  }

  const startPos = Y.createAbsolutePositionFromRelativePosition(
    startRelativeRange.point,
    doc,
  );

  if (!startPos) {
    throw new Error('Unable to create absolute position');
  }

  const startBlock = Editor.above(editor, {
    at: startPoint.path,
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
  }) as NodeEntry<Element>;

  if (!startBlock) {
    throw new Error('Block not found');
  }

  let yText = getText(startTextId, sharedRoot);

  if (!yText) {
    const data = startBlock[0].data as BlockData;
    const delta = new Delta(data.delta || []);

    yText = compatibleDataDeltaToYText(sharedRoot, delta.ops, startBlock[0].blockId as string);
  }

  const startOffset = Math.min(startPos.index, yText.length);

  return { startBlock, startOffset };
}

export function isAtBlockStart(editor: Editor, point: Point) {
  const entry = Editor.above(editor, {
    at: point,
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.textId !== undefined,
  });

  if (!entry) return false;

  const [, path] = entry;
  const start = Editor.start(editor, path);

  return Point.equals(point, start);
}

export function isAtBlockEnd(editor: Editor, point: Point) {
  const entry = Editor.above(editor, {
    at: point,
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.textId !== undefined,
  });

  if (!entry) return false;

  const [, path] = entry;
  const end = Editor.end(editor, path);

  return Point.equals(point, end);
}

export function getSharedRoot(editor: YjsEditor) {
  if (!editor.sharedRoot || !editor.sharedRoot.doc) {
    throw new Error('Shared root not found');
  }

  return editor.sharedRoot;
}

export function getSelectionOrThrow(editor: YjsEditor, at?: BaseRange) {
  const newAt = at || editor.selection;

  if (!newAt) {
    throw new Error('Selection not found');
  }

  return newAt;
}

export function getBlockEntry(editor: YjsEditor, point?: Point) {
  const { selection } = editor;
  const at = point || (selection ? Editor.start(editor, selection) : null);

  if (!at) {
    throw new Error('Point not found');
  }

  const blockEntry = editor.above({
    at: point,
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
  });

  if (!blockEntry) {
    throw new Error('Block not found');
  }

  return blockEntry as NodeEntry<Element>;
}

export function handleNonParagraphBlockBackspaceAndEnterWithTxn(editor: YjsEditor, sharedRoot: YSharedRoot, block: YBlock, point: BasePoint) {
  const data = dataStringTOJson(block.get(YjsEditorKey.block_data));
  const blockType = block.get(YjsEditorKey.block_type);

  if (blockType === BlockType.ToggleListBlock && (data as ToggleListBlockData).level) {
    const [, path] = getBlockEntry(editor, point);

    Transforms.setNodes(editor, {
      data: {
        ...data,
        level: null,
      },
    }, { at: path });
    return;
  }

  const operations: (() => void)[] = [];

  operations.push(() => {
    turnToBlock(sharedRoot, block, BlockType.Paragraph, {});
  });
  executeOperations(sharedRoot, operations, 'turnToBlock');
}

export function handleLiftBlockOnBackspaceAndEnterWithTxn(editor: YjsEditor, sharedRoot: YSharedRoot, block: YBlock, point: Point) {
  const operations: (() => void)[] = [];
  const parent = getBlock(block.get(YjsEditorKey.block_parent), sharedRoot);
  const parentChildren = getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot);
  const index = parentChildren.toArray().findIndex((id) => id === block.get(YjsEditorKey.block_id));
  const [, path] = getBlockEntry(editor, point);

  const hasNextSibling = index < parentChildren.length - 1;
  const hasChildren = getChildrenArray(block.get(YjsEditorKey.block_children), sharedRoot).length > 0;

  if (preventLiftNode(editor, block.get(YjsEditorKey.block_id))) {
    return false;
  }

  if (!hasChildren && !hasNextSibling) {
    let newPath: number[] | undefined;

    operations.push(() => {
      newPath = liftEditorNode(editor, sharedRoot, block, point);
    });
    executeOperations(sharedRoot, operations, 'liftBlock');
    if (!newPath) return false;

    const newPoint = {
      path: [...newPath, ...point.path.slice(path.length)],
      offset: point.offset,
    };

    // After the lift operation is complete, move the cursor to the start of the newly lifted block
    Transforms.select(editor, newPoint);
    return true;
  }

  return false;
}

export function handleMergeBlockBackwardWithTxn(editor: YjsEditor, node: Element, point: Point) {
  const operations: (() => void)[] = [];
  const sharedRoot = getSharedRoot(editor);

  try {
    const prevText = Editor.previous(editor, {
      at: point,
      match: (n) => {
        return !Editor.isEditor(n) && Element.isElement(n) && n.textId !== undefined;
      },
      voids: true,
    });

    if (!prevText) {
      return;
    }

    const [, prevPath] = prevText as NodeEntry<Element>;
    const prevPoint = Editor.end(editor, prevPath);

    if (!prevPoint) {
      throw new Error('prevPoint not found');
    }

    const target = editor.above({
      at: prevPoint,
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
    });

    if (!target) {
      throw new Error('target not found');
    }

    const [targetNode] = target as NodeEntry<Element>;

    Transforms.select(editor, prevPoint);

    operations.push(() => {
      mergeBlocks(sharedRoot, node, targetNode);
    });
  } catch (e) {
    // at the beginning of the document
    console.info('at the beginning of the document');
  }

  executeOperations(sharedRoot, operations, 'deleteBlockBackward');
}

export function handleMergeBlockForwardWithTxn(editor: YjsEditor, node: Element, point: Point) {
  const operations: (() => void)[] = [];
  const sharedRoot = getSharedRoot(editor);

  try {
    const nextPoint = Editor.after(editor, point);

    if (!nextPoint) {
      throw new Error('nextPoint not found');
    }

    const source = editor.above({
      at: nextPoint,
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
    });

    if (!source) {
      throw new Error('source not found');
    }

    const [sourceNode] = source as NodeEntry<Element>;

    operations.push(() => {
      mergeBlocks(sharedRoot, sourceNode, node);
    });
  } catch (e) {
    // at the end of the document
    console.info('at the end of the document');
  }

  executeOperations(sharedRoot, operations, 'deleteBlockForward');
}

export function preventIndentNode(editor: YjsEditor, blockId: string) {
  const sharedRoot = getSharedRoot(editor);
  const block = getBlock(blockId, sharedRoot);
  const parent = getBlock(block.get(YjsEditorKey.block_parent), sharedRoot);
  const parentChildren = getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot);
  const index = parentChildren.toArray().findIndex((id) => id === block.get(YjsEditorKey.block_id));

  if (index === 0) {
    return true;
  }

  // Get the previous sibling
  const previousSiblingId = parentChildren.get(index - 1);
  const previousSibling = getBlock(previousSiblingId, sharedRoot);

  if (!previousSibling) {
    return true;
  }

  // Check if the parent block is a container block
  if (!CONTAINER_BLOCK_TYPES.includes(previousSibling.get(YjsEditorKey.block_type))) {
    return true;
  }

  return false;
}

export function preventLiftNode(editor: YjsEditor, blockId: string) {
  const [, path] = findSlateEntryByBlockId(editor, blockId);
  const level = path.length;

  if (level < 2) {
    return true;
  }

  return false;
}

export function liftEditorNode(editor: YjsEditor, sharedRoot: YSharedRoot, block: YBlock, point: Point) {
  if (preventLiftNode(editor, block.get(YjsEditorKey.block_id))) {
    return;
  }

  // Find the path of the current block
  const [, path] = getBlockEntry(editor, point);
  const parentPath = path.slice(0, -1);

  // This is to prevent errors caused by invalid paths when the original node is deleted during the lift process
  Transforms.select(editor, Editor.start(editor, parentPath));

  liftBlock(sharedRoot, block);

  // Calculate the position where the new block should be after the lift operation
  const nextPath = Path.next(parentPath);

  return nextPath;

}

export function isEntireDocumentSelected(editor: YjsEditor) {
  const selection = getSelectionOrThrow(editor);
  const [start, end] = Editor.edges(editor, selection);
  const startEdge = Editor.start(editor, []);
  const endEdge = Editor.end(editor, []);

  return Point.equals(start, startEdge) && Point.equals(end, endEdge);
}

export function handleDeleteEntireDocumentWithTxn(editor: YjsEditor) {
  const sharedRoot = getSharedRoot(editor);
  const operations = [() => {
    editor.deselect();

    const blocks = getBlocks(sharedRoot);
    const pageId = getPageId(sharedRoot);
    const blockId = appendEmptyParagraph(sharedRoot);

    blocks.forEach((_, k) => {
      if (k !== pageId && k !== blockId) {
        deleteBlock(sharedRoot, k);
      }
    });

  }];

  executeOperations(sharedRoot, operations, 'deleteEntireDocument');
  Transforms.select(editor, Editor.start(editor, [0]));
}

export function getNodeAtPath(children: Descendant[], path: Path): Descendant | null {
  let currentNode: Descendant | null = null;
  let currentChildren = children;

  for (let i = 0; i < path.length; i++) {
    const index = path[i];

    if (index >= currentChildren.length) {
      return null;
    }

    currentNode = currentChildren[index];
    if (i === path.length - 1) {
      return currentNode;
    }

    if (!Element.isElement(currentNode) || !currentNode.children) {
      return null;
    }

    currentChildren = currentNode.children;
  }

  return currentNode;
}

export function getSelectionTexts(editor: ReactEditor) {
  const selection = editor.selection;

  if (!selection) return [];

  const texts: Text[] = [];

  const isExpanded = Range.isExpanded(selection);

  if (isExpanded) {
    const start = Range.start(selection);
    const end = Range.end(selection);

    Array.from(
      Editor.nodes(editor, {
        at: {
          anchor: start,
          focus: end,
        },
        match: (n) => Text.isText(n),
      }),
    ).forEach((match) => {
      const node = match[0] as Element;

      if (Text.isText(node)) {
        texts.push(node);
      }
    });
  }

  return texts;
}

export function getOffsetPointFromSlateRange(editor: YjsEditor, point: BasePoint): { offset: number; textId: string } {

  const [node] = editor.nodes({
    at: point,
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.textId !== undefined,
  });

  if (!node) {
    throw new Error('Node not found');
  }

  const [textNode] = node as NodeEntry<Element>;

  return {
    textId: textNode.textId as string,
    offset: calculateOffsetRelativeToParent(textNode, point),
  };
}

export function getSlatePointFromOffset(editor: YjsEditor, range: { offset: number; textId: string }): BasePoint {
  const [node] = editor.nodes({
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.textId === range.textId,
  });

  if (!node) {
    throw new Error('Node not found');
  }

  const [textNode, path] = node as NodeEntry<Element>;

  const start = calculatePointFromParentOffset(textNode, path, range.offset);

  return start;
}

export function addBlock(editor: YjsEditor, {
  ty,
  data,
}: {
  ty: BlockType,
  data: BlockData,
}, parent: YBlock, index: number): string | undefined {
  const sharedRoot = getSharedRoot(editor);
  const operations: (() => void)[] = [];

  let newBlockId: string | undefined;

  operations.push(() => {
    const newBlock = createBlock(sharedRoot, {
      ty,
      data,
    });

    newBlockId = newBlock.get(YjsEditorKey.block_id);

    updateBlockParent(sharedRoot, newBlock, parent, index);

    extendNextSiblingsToToggleHeading(sharedRoot, newBlock);
  });

  executeOperations(sharedRoot, operations, 'addBlock');

  return newBlockId;
}

