import {
  BlockData,
  BlockType, ToggleListBlockData,
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
import { BaseRange, Editor, Element, Node, NodeEntry, Path, Range, Transforms } from 'slate';
import * as Y from 'yjs';
import { YjsEditor } from '../plugins/withYjs';
import { slatePointToRelativePosition } from './positions';

export function getText (textId: string, sharedRoot: YSharedRoot) {

  const document = sharedRoot.get(YjsEditorKey.document);
  const meta = document.get(YjsEditorKey.meta) as YMeta;
  const textMap = meta.get(YjsEditorKey.text_map) as YTextMap;

  return textMap.get(textId);
}

function assertDocExists (sharedRoot: YSharedRoot): YDoc {
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

export function handleCollapsedBreak (editor: YjsEditor, sharedRoot: YSharedRoot, at: BaseRange) {
  const { startBlock, startOffset } = getBreakInfo(editor, sharedRoot, at);
  const [blockNode] = startBlock;
  const blockId = blockNode.blockId as string;
  const block = getBlock(blockId, sharedRoot);

  if (!block) {
    throw new Error('Block not found');
  }

  const { operations, select } = getSplitBlockOperations(sharedRoot, block, startOffset);

  executeOperations(sharedRoot, operations, 'insertBreak');

  if (select) {
    moveToNextLine(editor, block, at, blockId);
  } else {
    Transforms.select(editor, Editor.start(editor, at));
  }
}

export function removeRange (editor: YjsEditor, sharedRoot: YSharedRoot, range: Range) {
  const { startBlock, endBlock, middleBlocks, startRange, endRange } = getAffectedBlocks(editor, range);
  const operations: (() => void)[] = [];
  const isSameBlock = Path.compare(startBlock[1], endBlock[1]) === 0;

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
  removeRange(editor, sharedRoot, range);

  const selection = editor.selection;

  if (!selection) return;

  handleCollapsedBreak(editor, sharedRoot, selection);
}

export function turnToBlock<T extends BlockData> (sharedRoot: YSharedRoot, sourceBlock: YBlock, type: BlockType, data: T) {
  const newBlock = createBlock(sharedRoot, {
    ty: type,
    data,
  });

  const sourceTextId = sourceBlock.get(YjsEditorKey.block_external_id);
  const targetTextId = newBlock.get(YjsEditorKey.block_external_id);

  if (!sourceTextId || !targetTextId) {
    throw new Error('Text id not found');
  }

  const sourceText = getText(sourceTextId, sharedRoot);
  const targetText = getText(targetTextId, sharedRoot);

  targetText.applyDelta(sourceText.toDelta());

  transferChildren(sharedRoot, sourceBlock, newBlock);

  const parent = getBlock(sourceBlock.get(YjsEditorKey.block_parent), sharedRoot);

  if (!parent) return;

  const parentChildren = getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot);
  const index = parentChildren.toArray().findIndex((id) => id === sourceBlock.get(YjsEditorKey.block_id));

  // delete source block
  deleteBlock(sharedRoot, sourceBlock.get(YjsEditorKey.block_id));

  updateBlockParent(sharedRoot, newBlock, parent, index);
}

function getSplitBlockOperations (sharedRoot: YSharedRoot, block: YBlock, offset: number): {
  select: boolean;
  operations: (() => void)[];
} {
  const operations: (() => void)[] = [];

  if (offset === 0) {
    const yText = getText(block.get(YjsEditorKey.block_external_id), sharedRoot);

    if (yText.length === 0) {
      operations.push(() => {
        turnToBlock(sharedRoot, block, BlockType.Paragraph, {});
      });
      return { operations, select: false };
    } else {
      operations.push(() => {
        const listBlockTypes = [BlockType.TodoListBlock, BlockType.BulletedListBlock, BlockType.NumberedListBlock];
        const type = block.get(YjsEditorKey.block_type);
        const data = dataStringTOJson(block.get(YjsEditorKey.block_data));
        const isList = listBlockTypes.includes(type);
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
    }

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

  const isSameBlock = Path.compare(startBlock[1], endBlock[1]) === 0;

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
  const relativeOffset = slatePointToRelativePosition(sharedRoot, editor, range.anchor);
  const startPos = Y.createAbsolutePositionFromRelativePosition(relativeOffset.point, assertDocExists(sharedRoot));
  const endRelativeOffset = slatePointToRelativePosition(sharedRoot, editor, range.focus);
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

  if ([
    BlockType.ToggleListBlock,
    BlockType.TodoListBlock,
    BlockType.Paragraph,
    BlockType.QuoteBlock,
    BlockType.BulletedListBlock,
    BlockType.NumberedListBlock,
  ].includes(targetType)) {
    transferChildren(sharedRoot, sourceBlock, targetBlock);
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

    case BlockType.HeadingBlock:
    case BlockType.QuoteBlock:
      return BlockType.Paragraph;
    default:
      return block.get(YjsEditorKey.block_type);
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

  if (blockType === BlockType.ToggleListBlock) {
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

export function transferChildren (sharedRoot: YSharedRoot, sourceBlock: YBlock, targetBlock: YBlock) {
  const sourceChildrenArray = getChildrenArray(sourceBlock.get(YjsEditorKey.block_children), sharedRoot);

  const targetChildrenArray = ensureBlockHasChildren(sharedRoot, targetBlock);

  if (!sourceChildrenArray || !targetChildrenArray) return;
  if (sourceChildrenArray.length > 0) {
    deepCopyChildren(sharedRoot, sourceChildrenArray, targetChildrenArray, targetBlock.get(YjsEditorKey.block_id));
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