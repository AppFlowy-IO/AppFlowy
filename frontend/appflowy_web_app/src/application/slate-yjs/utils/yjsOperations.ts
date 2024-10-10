import { CONTAINER_BLOCK_TYPES, ListBlockTypes } from '@/application/slate-yjs/command/const';
import {
  BlockData,
  BlockType,
  ToggleListBlockData,
  YBlock,
  YBlocks,
  YChildrenMap,
  YDoc,
  YjsEditorKey,
  YMeta,
  YSharedRoot,
  YTextMap,
} from '@/application/types';

import { nanoid } from 'nanoid';
import Delta, { Op } from 'quill-delta';
import { BaseRange, Descendant, Editor, Element, Node, NodeEntry, Path, Point, Range, Transforms } from 'slate';
import * as Y from 'yjs';
import { YjsEditor } from '../plugins/withYjs';
import { slatePointToRelativePosition } from './positions';

export function createEmptyDocument () {
  const doc = new Y.Doc();
  const sharedRoot = doc.getMap(YjsEditorKey.data_section) as YSharedRoot;
  const document = new Y.Map();
  const blocks = new Y.Map() as YBlocks;
  const pageId = nanoid(8);
  const meta = new Y.Map();
  const childrenMap = new Y.Map() as YChildrenMap;
  const textMap = new Y.Map() as YTextMap;

  const block = new Y.Map();

  block.set(YjsEditorKey.block_id, pageId);
  block.set(YjsEditorKey.block_type, BlockType.Page);
  block.set(YjsEditorKey.block_children, pageId);
  block.set(YjsEditorKey.block_external_id, pageId);
  block.set(YjsEditorKey.block_external_type, YjsEditorKey.text);
  block.set(YjsEditorKey.block_data, '');
  blocks.set(pageId, block);

  document.set(YjsEditorKey.page_id, pageId);
  document.set(YjsEditorKey.blocks, blocks);
  document.set(YjsEditorKey.meta, meta);
  childrenMap.set(pageId, new Y.Array());
  meta.set(YjsEditorKey.children_map, childrenMap);
  meta.set(YjsEditorKey.text_map, textMap);
  sharedRoot.set(YjsEditorKey.document, document);

  return doc;
}

export function getText (textId: string, sharedRoot: YSharedRoot) {

  const document = sharedRoot.get(YjsEditorKey.document);
  const meta = document.get(YjsEditorKey.meta) as YMeta;
  const textMap = meta.get(YjsEditorKey.text_map) as YTextMap;

  return textMap.get(textId);
}

export function assertDocExists (sharedRoot: YSharedRoot): YDoc {
  const doc = sharedRoot.doc;

  if (!doc) {
    throw new Error('Document not found');
  }

  return doc;
}

export function getChildrenMap (sharedRoot: YSharedRoot) {
  const document = sharedRoot.get(YjsEditorKey.document);
  const meta = document.get(YjsEditorKey.meta) as YMeta;
  const childrenMap = meta.get(YjsEditorKey.children_map) as YChildrenMap;

  return childrenMap;
}

export function getChildrenArray (childrenId: string, sharedRoot: YSharedRoot) {
  const childrenMap = getChildrenMap(sharedRoot);

  return childrenMap.get(childrenId);
}

export function getDocument (sharedRoot: YSharedRoot) {
  return sharedRoot.get(YjsEditorKey.document);
}

export function getBlock (blockId: string, sharedRoot: YSharedRoot) {
  const document = sharedRoot.get(YjsEditorKey.document);
  const blocks = document.get(YjsEditorKey.blocks) as YBlocks;

  return blocks.get(blockId);
}

export function generateBlockId () {
  return nanoid(8);
}

export function createBlock (sharedRoot: YSharedRoot, {
  ty,
  data,
}: {
  ty: BlockType;
  data: object;
}): YBlock {
  const block = new Y.Map();
  const id = generateBlockId();

  block.set(YjsEditorKey.block_id, id);
  block.set(YjsEditorKey.block_type, ty);
  block.set(YjsEditorKey.block_children, id);
  block.set(YjsEditorKey.block_external_id, id);
  block.set(YjsEditorKey.block_external_type, 'text');
  block.set(YjsEditorKey.block_data, JSON.stringify(data));

  const document = getDocument(sharedRoot);
  const blocks = document.get(YjsEditorKey.blocks) as YBlocks;

  blocks.set(id, block);

  const meta = document.get(YjsEditorKey.meta) as YMeta;
  const childrenMap = meta.get(YjsEditorKey.children_map) as YChildrenMap;
  const textMap = meta.get(YjsEditorKey.text_map) as YTextMap;

  childrenMap.set(id, new Y.Array());
  textMap.set(id, new Y.Text());

  return block as YBlock;
}

export function updateBlockParent (sharedRoot: YSharedRoot, block: YBlock, parent: YBlock, index: number) {
  block.set(YjsEditorKey.block_parent, parent.get(YjsEditorKey.block_id));
  const parentChildren = getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot);

  parentChildren.insert(index, [block.get(YjsEditorKey.block_id)]);
}

export function handleCollapsedBreakWithTxn (editor: YjsEditor, sharedRoot: YSharedRoot, at: BaseRange) {
  const { startBlock, startOffset } = getBreakInfo(editor, sharedRoot, at);
  const [blockNode, path] = startBlock;
  const blockId = blockNode.blockId as string;
  const block = getBlock(blockId, sharedRoot);

  if (!block) {
    throw new Error('Block not found');
  }

  const blockType = block.get(YjsEditorKey.block_type);
  const yText = getText(block.get(YjsEditorKey.block_external_id), sharedRoot);

  if (yText.length === 0) {
    if (blockType !== BlockType.Paragraph) {
      handleNonParagraphBlockBackspaceAndEnterWithTxn(sharedRoot, block);
      return;
    }

    const point = Editor.start(editor, at);

    if (path.length > 1 && handleLiftBlockOnBackspaceAndEnterWithTxn(editor, sharedRoot, block, point)) {
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

export function removeRangeWithTxn (editor: YjsEditor, sharedRoot: YSharedRoot, range: Range) {
  const { startBlock, endBlock, middleBlocks, startRange, endRange } = getAffectedBlocks(editor, range);
  const operations: (() => void)[] = [];
  const isSameBlock = startBlock[0].blockId === endBlock[0].blockId;

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

export function liftChildren (sharedRoot: YSharedRoot, sourceBlock: YBlock, targetBlock: YBlock) {
  const sourceChildrenArray = getChildrenArray(sourceBlock.get(YjsEditorKey.block_children), sharedRoot);
  const targetParent = getBlock(targetBlock.get(YjsEditorKey.block_parent), sharedRoot);
  const targetChildrenArray = getChildrenArray(targetParent.get(YjsEditorKey.block_children), sharedRoot);

  if (!sourceChildrenArray || !targetChildrenArray) return;
  const index = targetChildrenArray.toArray().findIndex((id) => id === targetBlock.get(YjsEditorKey.block_id));
  const targetIndex = index !== -1 ? index + 1 : targetChildrenArray.length;

  if (sourceChildrenArray.length > 0) {
    deepCopyChildren(sharedRoot, sourceChildrenArray, targetChildrenArray, targetParent.get(YjsEditorKey.block_id), targetIndex);
    sourceChildrenArray.toArray().forEach((id) => {
      deleteBlock(sharedRoot, id);
    });
    sourceChildrenArray.delete(0, sourceChildrenArray.length);
  }
}

export function handleRangeBreak (editor: YjsEditor, sharedRoot: YSharedRoot, range: Range) {
  removeRangeWithTxn(editor, sharedRoot, range);

  const selection = editor.selection;

  if (!selection) return;

  handleCollapsedBreakWithTxn(editor, sharedRoot, selection);
}

export function copyBlockText (sharedRoot: YSharedRoot, sourceBlock: YBlock, targetBlock: YBlock) {
  const sourceTextId = sourceBlock.get(YjsEditorKey.block_external_id);
  const targetTextId = targetBlock.get(YjsEditorKey.block_external_id);

  if (!sourceTextId || !targetTextId) {
    throw new Error('Text id not found');
  }

  const sourceText = getText(sourceTextId, sharedRoot);
  const targetText = getText(targetTextId, sharedRoot);

  targetText.applyDelta(sourceText.toDelta());
}

export function turnToBlock<T extends BlockData> (sharedRoot: YSharedRoot, sourceBlock: YBlock, type: BlockType, data: T) {
  const newBlock = createBlock(sharedRoot, {
    ty: type,
    data,
  });

  copyBlockText(sharedRoot, sourceBlock, newBlock);

  const parent = getBlock(sourceBlock.get(YjsEditorKey.block_parent), sharedRoot);

  if (!parent) return;

  const parentChildren = getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot);
  const index = parentChildren.toArray().findIndex((id) => id === sourceBlock.get(YjsEditorKey.block_id));

  updateBlockParent(sharedRoot, newBlock, parent, index);

  if (CONTAINER_BLOCK_TYPES.includes(type)) {
    transferChildren(sharedRoot, sourceBlock, newBlock);
  } else {
    liftChildren(sharedRoot, sourceBlock, newBlock);
  }

  // delete source block
  deleteBlock(sharedRoot, sourceBlock.get(YjsEditorKey.block_id));
}

function getSplitBlockOperations (sharedRoot: YSharedRoot, block: YBlock, offset: number): {
  select: boolean;
  operations: (() => void)[];
} {
  const operations: (() => void)[] = [];

  if (offset === 0) {
    operations.push(() => {
      const type = block.get(YjsEditorKey.block_type);
      const data = dataStringTOJson(block.get(YjsEditorKey.block_data));
      const isList = ListBlockTypes.includes(type);
      const newBlock = createBlock(sharedRoot, {
        ty: isList ? type : BlockType.Paragraph,
        data: isList ? data : {},
      });
      const parent = getBlock(block.get(YjsEditorKey.block_parent), sharedRoot);
      const parentChildren = getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot);
      const index = parentChildren.toArray().findIndex((id) => id === block.get(YjsEditorKey.block_id));
      const prevIndex = index <= 0 ? 0 : index;

      updateBlockParent(sharedRoot, newBlock, parent, prevIndex);
    });

    return { operations, select: true };
  }

  const { nextLineDelta, parentInfo } = prepareBreakOperation(sharedRoot, block, offset);

  operations.push(() => splitBlock(sharedRoot, block, offset, nextLineDelta, parentInfo));

  return { operations, select: true };
}

function moveToNextLine (editor: Editor, block: YBlock, at: BaseRange, blockId: string) {
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

export function getNextSiblingBlockPath (editor: Editor, blockId: string) {
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

export function getAffectedBlocks (editor: YjsEditor, range: Range): {
  startBlock: NodeEntry<Element>;
  endBlock: NodeEntry<Element>;
  middleBlocks: NodeEntry<Element>[];
  startRange: BaseRange;
  endRange: BaseRange;
} {
  const [start, end] = Range.edges(range);
  let startRange = range;
  let endRange = range;

  const startBlock = Editor.above(editor, {
    at: start,
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
  }) as NodeEntry<Element>;

  const endBlock = Editor.above(editor, {
    at: end,
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
  }) as NodeEntry<Element>;

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

    startRange = Editor.range(editor, start, Editor.end(editor, startBlock[1]));
    endRange = Editor.range(editor, Editor.start(editor, endBlock[1]), end);
  }

  return { startBlock, endBlock, middleBlocks, startRange, endRange };
}

function getTextIdFromSlateNode (node: Element) {
  return node.textId ?? (node.children[0] as Element).textId;
}

export function deleteSlateRangeInBlock (sharedRoot: YSharedRoot, editor: Editor, block: Element, range: BaseRange) {
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

export function deleteRangeInBlock (
  sharedRoot: YSharedRoot,
  block: Element,
  start: number,
  end: number,
) {
  const textId = getTextIdFromSlateNode(block);

  if (!textId) {
    throw new Error('Text id not found');
  }

  const yText = getText(textId, sharedRoot);

  yText.delete(start, end - start);

}

export function mergeBlocks (
  sharedRoot: YSharedRoot,
  sourceBlock: Element,
  targetBlock: Element,
) {
  const sourceTextId = getTextIdFromSlateNode(sourceBlock);
  const targetTextId = getTextIdFromSlateNode(targetBlock);

  if (!sourceTextId || !targetTextId) {
    throw new Error('Text id not found');
  }

  const sourceYText = getText(sourceTextId, sharedRoot);
  const targetYText = getText(targetTextId, sharedRoot);

  const sourceOps = sourceYText.toDelta() as Op[];
  const targetOps = targetYText.toDelta() as Op[];

  const sourceDelta = new Delta(sourceOps);
  const targetDelta = new Delta(targetOps);
  const concat = targetDelta.concat(sourceDelta);

  targetYText.delete(0, targetYText.length);
  targetYText.applyDelta(concat.ops);

  const sourceBlockId = sourceBlock.blockId as string;
  const targetBlockId = targetBlock.blockId as string;

  mergeBlockChildren(sharedRoot, getBlock(sourceBlockId, sharedRoot), getBlock(targetBlockId, sharedRoot));
  deleteBlock(sharedRoot, sourceBlock.blockId as string);
}

function mergeBlockChildren (sharedRoot: YSharedRoot, sourceBlock: YBlock, targetBlock: YBlock) {
  const targetType = targetBlock.get(YjsEditorKey.block_type);

  if (CONTAINER_BLOCK_TYPES.includes(targetType)) {
    transferChildren(sharedRoot, sourceBlock, targetBlock, 0);
  } else {
    liftChildren(sharedRoot, sourceBlock, targetBlock);
  }
}

export function deleteBlock (sharedRoot: YSharedRoot, blockId: string) {
  const block = getBlock(blockId, sharedRoot);

  if (!block) return;

  const document = getDocument(sharedRoot);
  const blocks = document.get(YjsEditorKey.blocks) as YBlocks;
  const parentId = block.get(YjsEditorKey.block_parent);

  blocks.delete(blockId);

  const meta = document.get(YjsEditorKey.meta) as YMeta;
  const childrenMap = meta.get(YjsEditorKey.children_map) as YChildrenMap;
  const textMap = meta.get(YjsEditorKey.text_map) as YTextMap;

  childrenMap.delete(blockId);
  textMap.delete(blockId);

  const parent = getBlock(parentId, sharedRoot);

  if (!parent) return;

  const parentChildren = getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot);
  const index = parentChildren.toArray().findIndex((id) => id === blockId);

  if (index !== -1) {
    parentChildren.delete(index, 1);
  }
}

export function getBreakInfo (editor: YjsEditor, sharedRoot: YSharedRoot, at: BaseRange) {
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

  const yText = getText(startTextId, sharedRoot);
  const startOffset = Math.min(startPos.index, yText.length);

  return { startBlock, startOffset };
}

export function prepareBreakOperation (sharedRoot: YSharedRoot, block: YBlock, offset: number) {
  const yText = getText(block.get(YjsEditorKey.block_external_id), sharedRoot);
  const ops = yText.toDelta() as Op[];
  const delta = new Delta(ops);
  const nextLineDelta = delta.slice(offset);

  const parentId = block.get(YjsEditorKey.block_parent);
  const parent = getBlock(parentId, sharedRoot);

  if (!parent) {
    throw new Error('Parent block not found');
  }

  const parentChildren = getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot);
  const targetIndex = parentChildren.toArray().findIndex((id) => id === block.get(YjsEditorKey.block_id));

  return { nextLineDelta, parentInfo: { parent, targetIndex, parentChildren } };
}

export function getSplitBlockType (block: YBlock) {
  switch (block.get(YjsEditorKey.block_type)) {
    case BlockType.ToggleListBlock: {
      const data = dataStringTOJson(block.get(YjsEditorKey.block_data)) as ToggleListBlockData;

      if (!data.collapsed) {
        return BlockType.Paragraph;
      } else {
        return block.get(YjsEditorKey.block_type);
      }
    }

    case BlockType.BulletedListBlock:
    case BlockType.NumberedListBlock:
    case BlockType.TodoListBlock:
      return block.get(YjsEditorKey.block_type);

    default:
      return BlockType.Paragraph;
  }
}

export function splitBlock (sharedRoot: YSharedRoot, block: YBlock, offset: number, nextLineDelta: Delta, parentInfo: {
  parent: YBlock,
  targetIndex: number,
  parentChildren: Y.Array<string>
}) {
  const { parent, targetIndex, parentChildren } = parentInfo;
  const yText = getText(block.get(YjsEditorKey.block_external_id), sharedRoot);

  yText.delete(offset, yText.length - offset);

  const newBlock = createBlock(sharedRoot, {
    ty: getSplitBlockType(block),
    data: {},
  });

  const newBlockText = getText(newBlock.get(YjsEditorKey.block_external_id), sharedRoot);

  newBlockText.applyDelta(nextLineDelta.ops);

  const blockType = block.get(YjsEditorKey.block_type);

  if (blockType === BlockType.ToggleListBlock || blockType === BlockType.QuoteBlock) {
    const data = dataStringTOJson(block.get(YjsEditorKey.block_data)) as ToggleListBlockData;

    if (!data.collapsed) {
      const blockChildrenArray = getChildrenArray(block.get(YjsEditorKey.block_children), sharedRoot);

      if (blockChildrenArray) {
        updateBlockParent(sharedRoot, newBlock, block, 0);
      }

      return;
    }
  } else {
    transferChildren(sharedRoot, block, newBlock);
  }

  const index = targetIndex !== -1 ? targetIndex + 1 : parentChildren.length;

  updateBlockParent(sharedRoot, newBlock, parent, index);
}

function ensureBlockHasChildren (sharedRoot: YSharedRoot, block: YBlock) {
  const childrenArray = getChildrenArray(block.get(YjsEditorKey.block_children), sharedRoot);

  if (!childrenArray) {
    const newArray = new Y.Array<string>();
    const childrenMap = getChildrenMap(sharedRoot);

    childrenMap.set(block.get(YjsEditorKey.block_children), newArray);
  }

  return getChildrenArray(block.get(YjsEditorKey.block_children), sharedRoot);
}

export function transferChildren (sharedRoot: YSharedRoot, sourceBlock: YBlock, targetBlock: YBlock, index?: number) {
  const sourceChildrenArray = getChildrenArray(sourceBlock.get(YjsEditorKey.block_children), sharedRoot);

  const targetChildrenArray = ensureBlockHasChildren(sharedRoot, targetBlock);

  if (!sourceChildrenArray || !targetChildrenArray) return;
  if (sourceChildrenArray.length > 0) {
    deepCopyChildren(sharedRoot, sourceChildrenArray, targetChildrenArray, targetBlock.get(YjsEditorKey.block_id), index);
    sourceChildrenArray.toArray().forEach((id) => {
      deleteBlock(sharedRoot, id);
    });
    sourceChildrenArray.delete(0, sourceChildrenArray.length);
  }
}

export function executeOperations (sharedRoot: YSharedRoot, operations: (() => void)[], operationName: string) {
  console.time(operationName);
  const doc = assertDocExists(sharedRoot);

  doc.transact(() => {
    operations.forEach((op) => op());
  });

  console.timeEnd(operationName);
}

export function dataStringTOJson (data: string): object {
  try {
    return JSON.parse(data);
  } catch (e) {
    return {};
  }
}

function deepCopyChildren (sharedRoot: YSharedRoot, sourceArray: Y.Array<string>, targetArray: Y.Array<string>, targetBlockId: string, index?: number) {

  const sourceArraySorted = index === undefined ? sourceArray.toArray() : sourceArray.toArray().reverse();

  sourceArraySorted.forEach((childId) => {
    const sourceChild = getBlock(childId, sharedRoot);

    if (sourceChild) {
      const oldData = dataStringTOJson(sourceChild.get(YjsEditorKey.block_data));
      const newChild = createBlock(sharedRoot, {
        ty: sourceChild.get(YjsEditorKey.block_type),
        data: oldData,
      });

      const sourceText = getText(sourceChild.get(YjsEditorKey.block_external_id), sharedRoot);
      const targetText = getText(newChild.get(YjsEditorKey.block_external_id), sharedRoot);

      targetText.applyDelta(sourceText.toDelta());

      const sourceChildrenArray = getChildrenArray(childId, sharedRoot);

      if (sourceChildrenArray && sourceChildrenArray.length > 0) {
        const newChildrenArray = getChildrenArray(newChild.get(YjsEditorKey.block_children), sharedRoot);

        if (newChildrenArray) {
          deepCopyChildren(sharedRoot, sourceChildrenArray, newChildrenArray, newChild.get(YjsEditorKey.block_id));
        }
      }

      const targetIndex = index !== undefined ? index : targetArray.length;

      updateBlockParent(sharedRoot, newChild, getBlock(targetBlockId, sharedRoot), targetIndex);
    }
  });
}

export function isAtBlockStart (editor: Editor, point: Point) {
  const entry = Editor.above(editor, {
    at: point,
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.textId !== undefined,
  });

  if (!entry) return false;

  const [, path] = entry;
  const start = Editor.start(editor, path);

  return Point.equals(point, start);
}

export function isAtBlockEnd (editor: Editor, point: Point) {
  const entry = Editor.above(editor, {
    at: point,
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.textId !== undefined,
  });

  if (!entry) return false;

  const [, path] = entry;
  const end = Editor.end(editor, path);

  return Point.equals(point, end);
}

export function getSharedRoot (editor: YjsEditor) {
  if (!editor.sharedRoot || !editor.sharedRoot.doc) {
    throw new Error('Shared root not found');
  }

  return editor.sharedRoot;
}

export function getSelectionOrThrow (editor: YjsEditor, at?: BaseRange) {
  const newAt = at || editor.selection;

  if (!newAt) {
    throw new Error('Selection not found');
  }

  return newAt;
}

export function getBlockEntry (editor: YjsEditor, point?: Point) {
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

export function handleNonParagraphBlockBackspaceAndEnterWithTxn (sharedRoot: YSharedRoot, block: YBlock) {
  const operations: (() => void)[] = [];

  operations.push(() => {
    turnToBlock(sharedRoot, block, BlockType.Paragraph, {});
  });
  executeOperations(sharedRoot, operations, 'turnToBlock');
}

export function handleLiftBlockOnTabWithTxn (editor: YjsEditor, sharedRoot: YSharedRoot, block: YBlock, point: Point) {
  const operations: (() => void)[] = [];
  const [, path] = getBlockEntry(editor, point);

  let newPath: number[] | undefined;

  operations.push(() => {
    newPath = liftEditorNode(editor, sharedRoot, block, point);
  });

  executeOperations(sharedRoot, operations, 'liftBlock');
  if (!newPath) return;

  const newPoint = {
    path: [...newPath, ...point.path.slice(path.length)],
    offset: point.offset,
  };

  // After the lift operation is complete, move the cursor to the start of the newly lifted block
  Transforms.select(editor, newPoint);
}

export function handleLiftBlockOnBackspaceAndEnterWithTxn (editor: YjsEditor, sharedRoot: YSharedRoot, block: YBlock, point: Point) {
  const operations: (() => void)[] = [];
  const parent = getBlock(block.get(YjsEditorKey.block_parent), sharedRoot);
  const parentChildren = getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot);
  const index = parentChildren.toArray().findIndex((id) => id === block.get(YjsEditorKey.block_id));
  const [, path] = getBlockEntry(editor, point);

  const hasNextSibling = index < parentChildren.length - 1;
  const hasChildren = getChildrenArray(block.get(YjsEditorKey.block_children), sharedRoot).length > 0;

  if (!hasChildren && !hasNextSibling) {
    let newPath: number[] | undefined;

    operations.push(() => {
      newPath = liftEditorNode(editor, sharedRoot, block, point);
    });
    executeOperations(sharedRoot, operations, 'liftBlock');
    if (!newPath) return;

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

export function handleIndentBlockWithTxn (editor: YjsEditor, sharedRoot: YSharedRoot, block: YBlock, point: Point) {
  const operations: (() => void)[] = [];
  const parent = getBlock(block.get(YjsEditorKey.block_parent), sharedRoot);
  const parentChildren = getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot);
  const index = parentChildren.toArray().findIndex((id) => id === block.get(YjsEditorKey.block_id));
  const [, path] = getBlockEntry(editor, point);

  // Check if the block can be indented (not the first child)
  if (index === 0) {
    return false;
  }

  // Get the previous sibling
  const previousSiblingId = parentChildren.get(index - 1);
  const previousSibling = getBlock(previousSiblingId, sharedRoot);

  if (!previousSibling) {
    return false;
  }

  // Check if the parent block is a container block
  if (!CONTAINER_BLOCK_TYPES.includes(previousSibling.get(YjsEditorKey.block_type))) {
    return false;
  }

  let newPath: number[] | undefined;

  operations.push(() => {
    newPath = indentEditorNode(editor, sharedRoot, block, point);
  });

  executeOperations(sharedRoot, operations, 'indentBlock');

  if (!newPath) return;

  const newPoint = {
    path: [...newPath, ...point.path.slice(path.length)],
    offset: point.offset,
  };

  console.log('newPath:', newPath, 'newPoint:', newPoint);

  Transforms.select(editor, newPoint);

  return true;
}

export function handleMergeBlockBackwardWithTxn (editor: YjsEditor, node: Element, point: Point) {
  const operations: (() => void)[] = [];
  const sharedRoot = getSharedRoot(editor);

  try {
    const prevPoint = Editor.before(editor, point);

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

    operations.push(() => {
      Transforms.move(editor, { distance: 1, reverse: true });
      mergeBlocks(sharedRoot, node, targetNode);
    });
  } catch (e) {
    // at the beginning of the document
    console.info('at the beginning of the document');
  }

  executeOperations(sharedRoot, operations, 'deleteBlockBackward');
}

export function handleMergeBlockForwardWithTxn (editor: YjsEditor, node: Element, point: Point) {
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

export function liftEditorNode (editor: YjsEditor, sharedRoot: YSharedRoot, block: YBlock, point: Point) {
  // Find the path of the current block
  const [, path] = getBlockEntry(editor, point);
  const parentPath = path.slice(0, -1);
  const level = path.length;

  if (level < 2) {
    return;
  }

  // This is to prevent errors caused by invalid paths when the original node is deleted during the lift process
  Transforms.select(editor, Editor.start(editor, parentPath));

  liftBlock(sharedRoot, block);

  // Calculate the position where the new block should be after the lift operation
  const nextPath = Path.next(parentPath);

  return nextPath;

}

export function indentEditorNode (editor: YjsEditor, sharedRoot: YSharedRoot, block: YBlock, point: Point) {
  // Find the path of the current block
  const [, path] = getBlockEntry(editor, point);
  const index = path[path.length - 1];

  console.log('indentEditorNode:', block.get(YjsEditorKey.block_id), 'at index', index, editor.children);
  // Check if the block can be indented (not the first child)
  if (index === 0) {
    console.warn('Cannot indent: block is the first child');
    return;
  }

  // Get the previous sibling's path
  const previousSiblingPath = Path.previous(path);
  const previousSibling = Editor.above(editor, {
    at: [...previousSiblingPath, 0],
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
  });
  const [previousNode] = previousSibling as NodeEntry<Element>;

  // This is to prevent errors caused by invalid paths when the original node is deleted during the indent process
  Transforms.select(editor, Editor.start(editor, previousSiblingPath));

  // Perform the indent operation on the Yjs document
  indentBlock(sharedRoot, block);

  const newPath = [...previousSiblingPath, previousNode.children.length];

  return newPath;

}

export function liftBlock (sharedRoot: YSharedRoot, block: YBlock) {
  const parentId = block.get(YjsEditorKey.block_parent);
  const parent = getBlock(parentId, sharedRoot);

  if (!parent) {
    console.warn('Cannot lift block: parent not found');
    return;
  }

  const grandParentId = parent.get(YjsEditorKey.block_parent);
  const grandParent = getBlock(grandParentId, sharedRoot);

  if (!grandParent) {
    console.warn('Cannot lift block: grandparent not found');
    return;
  }

  const grandParentChildrenArray = getChildrenArray(grandParent.get(YjsEditorKey.block_children), sharedRoot);

  if (!grandParentChildrenArray) {
    console.warn('Cannot lift block: grandparent children array not found');
    return;
  }

  const parentIndex = grandParentChildrenArray.toArray().findIndex((id) => id === parentId);

  if (parentIndex === -1) {
    console.warn('Cannot lift block: parent not found in grandparent\'s children');
    return;
  }

  moveNode(sharedRoot, block, grandParent, parentIndex + 1);
}

export function indentBlock (sharedRoot: YSharedRoot, block: YBlock) {
  const parentId = block.get(YjsEditorKey.block_parent);
  const parent = getBlock(parentId, sharedRoot);

  if (!parent) {
    console.warn('Cannot indent block: parent not found');
    return;
  }

  const parentChildrenArray = getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot);

  if (!parentChildrenArray) {
    console.warn('Cannot indent block: parent children array not found');
    return;
  }

  const blockIndex = parentChildrenArray.toArray().findIndex((id) => id === block.get(YjsEditorKey.block_id));

  if (blockIndex === -1) {
    console.warn('Cannot indent block: block not found in parent\'s children');
    return;
  }

  if (blockIndex === 0) {
    console.warn('Cannot indent block: block is the first child');
    return;
  }

  const previousSiblingId = parentChildrenArray.get(blockIndex - 1);
  const previousSibling = getBlock(previousSiblingId, sharedRoot);

  if (!previousSibling) {
    console.warn('Cannot indent block: previous sibling not found');
    return;
  }

  const previousSiblingChildrenArray = getChildrenArray(previousSibling.get(YjsEditorKey.block_children), sharedRoot);

  if (!previousSiblingChildrenArray) {
    console.warn('Cannot indent block: previous sibling children array not found');
    return;
  }

  return moveNode(sharedRoot, block, previousSibling, previousSiblingChildrenArray.length);
}

export function moveNode (sharedRoot: YSharedRoot, sourceBlock: YBlock, targetParent: YBlock, targetIndex: number) {
  console.log('moveNode:', sourceBlock.get(YjsEditorKey.block_id), 'to', targetParent.get(YjsEditorKey.block_id), 'at index', targetIndex);

  const copiedBlockId = deepCopyBlock(sharedRoot, sourceBlock);

  if (!copiedBlockId) {
    console.warn('Failed to copy block');
    return;
  }

  const copiedBlock = getBlock(copiedBlockId, sharedRoot);

  if (!copiedBlock) {
    console.warn('Copied block not found');
    return;
  }

  updateBlockParent(sharedRoot, copiedBlock, targetParent, targetIndex);

  deleteBlock(sharedRoot, sourceBlock.get(YjsEditorKey.block_id));

  return copiedBlockId;
}

export function deepCopyBlock (sharedRoot: YSharedRoot, sourceBlock: YBlock): string | null {
  try {
    const newBlock = createBlock(sharedRoot, {
      ty: sourceBlock.get(YjsEditorKey.block_type),
      data: dataStringTOJson(sourceBlock.get(YjsEditorKey.block_data)),
    });

    copyBlockText(sharedRoot, sourceBlock, newBlock);

    const sourceChildrenArray = getChildrenArray(sourceBlock.get(YjsEditorKey.block_children), sharedRoot);
    const targetChildrenArray = getChildrenArray(newBlock.get(YjsEditorKey.block_children), sharedRoot);

    if (sourceChildrenArray && targetChildrenArray) {
      deepCopyChildren(sharedRoot, sourceChildrenArray, targetChildrenArray, newBlock.get(YjsEditorKey.block_id));
    }

    return newBlock.get(YjsEditorKey.block_id);
  } catch (error) {
    console.error('Error in deepCopyBlock:', error);
    return null;
  }
}

export function isEntireDocumentSelected (editor: YjsEditor) {
  const selection = getSelectionOrThrow(editor);
  const [start, end] = Editor.edges(editor, selection);
  const startEdge = Editor.start(editor, []);
  const endEdge = Editor.end(editor, []);

  return Point.equals(start, startEdge) && Point.equals(end, endEdge);
}

export function getBlocks (sharedRoot: YSharedRoot) {
  const document = getDocument(sharedRoot);

  return document.get(YjsEditorKey.blocks) as YBlocks;
}

export function getPageId (sharedRoot: YSharedRoot) {
  const document = getDocument(sharedRoot);
  const pageId = document.get(YjsEditorKey.page_id) as string;

  return pageId;
}

export function appendEmptyParagraph (sharedRoot: YSharedRoot): string {
  const pageId = getPageId(sharedRoot);
  const page = getBlock(pageId, sharedRoot);
  const newBlock = createBlock(sharedRoot, {
    ty: BlockType.Paragraph,
    data: {},
  });

  updateBlockParent(sharedRoot, newBlock, page, 0);

  return newBlock.get(YjsEditorKey.block_id);
}

export function handleDeleteEntireDocumentWithTxn (editor: YjsEditor) {
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

export function getNodeAtPath (children: Descendant[], path: Path): Descendant | null {
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