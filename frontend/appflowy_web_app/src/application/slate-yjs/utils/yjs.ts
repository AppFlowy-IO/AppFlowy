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
import * as Y from 'yjs';
import {
  CONTAINER_BLOCK_TYPES,
  isEmbedBlockTypes,
  LIST_BLOCK_TYPES,
  TOGGLE_BLOCK_TYPES,
} from '@/application/slate-yjs/command/const';
import Delta, { Op } from 'quill-delta';

export function getTextMap(sharedRoot: YSharedRoot) {
  const document = sharedRoot.get(YjsEditorKey.document);
  const meta = document.get(YjsEditorKey.meta) as YMeta;

  return meta.get(YjsEditorKey.text_map) as YTextMap;
}

export function getText(textId: string, sharedRoot: YSharedRoot) {

  const textMap = getTextMap(sharedRoot);

  return textMap.get(textId);
}

export function getChildrenMap(sharedRoot: YSharedRoot) {
  const document = sharedRoot.get(YjsEditorKey.document);
  const meta = document.get(YjsEditorKey.meta) as YMeta;
  const childrenMap = meta.get(YjsEditorKey.children_map) as YChildrenMap;

  return childrenMap;
}

export function getChildrenArray(childrenId: string, sharedRoot: YSharedRoot) {
  const childrenMap = getChildrenMap(sharedRoot);

  return childrenMap.get(childrenId);
}

export function getDocument(sharedRoot: YSharedRoot) {
  return sharedRoot.get(YjsEditorKey.document);
}

export function getBlock(blockId: string, sharedRoot: YSharedRoot) {
  const document = sharedRoot.get(YjsEditorKey.document);
  const blocks = document.get(YjsEditorKey.blocks) as YBlocks;

  return blocks.get(blockId);
}

export function generateBlockId() {
  return nanoid(8);
}

export function createBlock(sharedRoot: YSharedRoot, {
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
  block.set(YjsEditorKey.block_data, JSON.stringify(data));

  const document = getDocument(sharedRoot);
  const blocks = document.get(YjsEditorKey.blocks) as YBlocks;

  blocks.set(id, block);

  const meta = document.get(YjsEditorKey.meta) as YMeta;
  const childrenMap = meta.get(YjsEditorKey.children_map) as YChildrenMap;

  childrenMap.set(id, new Y.Array());

  if (!isEmbedBlockTypes(ty)) {
    block.set(YjsEditorKey.block_external_id, id);
    block.set(YjsEditorKey.block_external_type, 'text');
    const textMap = meta.get(YjsEditorKey.text_map) as YTextMap;

    textMap.set(id, new Y.Text());
  }

  return block as YBlock;
}

export function assertDocExists(sharedRoot: YSharedRoot): YDoc {
  const doc = sharedRoot.doc;

  if (!doc) {
    throw new Error('Document not found');
  }

  return doc;
}

export function executeOperations(sharedRoot: YSharedRoot, operations: (() => void)[], operationName: string) {
  console.time(operationName);
  const doc = assertDocExists(sharedRoot);

  doc.transact(() => {
    operations.forEach((op) => op());
  });

  console.timeEnd(operationName);
}

export function updateBlockParent(sharedRoot: YSharedRoot, block: YBlock, parent: YBlock, index: number) {
  block.set(YjsEditorKey.block_parent, parent.get(YjsEditorKey.block_id));
  const parentChildren = getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot);

  if (index >= parentChildren.length) {
    parentChildren.push([block.get(YjsEditorKey.block_id)]);
    return;
  }

  parentChildren.insert(index, [block.get(YjsEditorKey.block_id)]);
}

export function getPageId(sharedRoot: YSharedRoot) {
  const document = getDocument(sharedRoot);

  if (!document) {
    throw new Error('Document not found');
  }

  const pageId = document.get(YjsEditorKey.page_id) as string;

  return pageId;
}

export function appendFirstEmptyParagraph(sharedRoot: YSharedRoot, defaultText: string) {
  const pageId = getPageId(sharedRoot);
  const page = getBlock(pageId, sharedRoot);

  executeOperations(sharedRoot, [() => {
    const newBlock = createBlock(sharedRoot, {
      ty: BlockType.Paragraph,
      data: {},
    });

    const newBlockText = getText(newBlock.get(YjsEditorKey.block_external_id), sharedRoot);

    newBlockText.insert(0, defaultText);

    updateBlockParent(sharedRoot, newBlock, page, 0);
  }], 'appendFirstEmptyParagraph');
}

export function createEmptyDocument() {
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

export function getBlockIndex(blockId: string, sharedRoot: YSharedRoot) {
  const block = getBlock(blockId, sharedRoot);
  const parent = getBlock(block.get(YjsEditorKey.block_parent), sharedRoot);
  const parentChildren = getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot);

  return parentChildren.toArray().findIndex((id) => id === blockId);
}

export function compatibleDataDeltaToYText(sharedRoot: YSharedRoot, ops: Op[], blockId: string) {
  const yText = new Y.Text();

  executeOperations(sharedRoot, [() => {

    yText.applyDelta(ops);

    const block = getBlock(blockId, sharedRoot);

    block.set(YjsEditorKey.block_external_id, blockId);
    block.set(YjsEditorKey.block_external_type, YjsEditorKey.text);
    const textMap = getTextMap(sharedRoot);

    textMap.set(blockId, yText);

  }], 'compatibleDataDeltaToYText');
  return yText;
}

export function deleteBlock(sharedRoot: YSharedRoot, blockId: string) {
  const block = getBlock(blockId, sharedRoot);

  if (!block) return;

  const document = getDocument(sharedRoot);
  const blocks = document.get(YjsEditorKey.blocks) as YBlocks;
  const parentId = block.get(YjsEditorKey.block_parent);

  const blockChildren = getChildrenArray(block.get(YjsEditorKey.block_children), sharedRoot).toArray();

  blockChildren.forEach((id) => {
    deleteBlock(sharedRoot, id);
  });

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

export function liftChildren(sharedRoot: YSharedRoot, sourceBlock: YBlock, targetBlock: YBlock) {
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

export function copyBlockText(sharedRoot: YSharedRoot, sourceBlock: YBlock, targetBlock: YBlock) {
  const sourceTextId = sourceBlock.get(YjsEditorKey.block_external_id);
  const targetTextId = targetBlock.get(YjsEditorKey.block_external_id);

  if (!sourceTextId || !targetTextId) {
    return;
  }

  const sourceText = getText(sourceTextId, sharedRoot);
  const targetText = getText(targetTextId, sharedRoot);

  if (!sourceText || !targetText) {
    return;
  }

  targetText.applyDelta(sourceText.toDelta());
}

export function prepareBreakOperation(sharedRoot: YSharedRoot, block: YBlock, offset: number) {
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

export function getSplitBlockType(block: YBlock) {
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

export function splitBlock(sharedRoot: YSharedRoot, block: YBlock, offset: number, nextLineDelta: Delta, parentInfo: {
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

  if (TOGGLE_BLOCK_TYPES.includes(blockType)) {
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

export function ensureBlockHasChildren(sharedRoot: YSharedRoot, block: YBlock) {
  const childrenArray = getChildrenArray(block.get(YjsEditorKey.block_children), sharedRoot);

  if (!childrenArray) {
    const newArray = new Y.Array<string>();
    const childrenMap = getChildrenMap(sharedRoot);

    childrenMap.set(block.get(YjsEditorKey.block_children), newArray);
  }

  return getChildrenArray(block.get(YjsEditorKey.block_children), sharedRoot);
}

export function transferChildren(sharedRoot: YSharedRoot, sourceBlock: YBlock, targetBlock: YBlock, index?: number) {
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

export function turnToBlock<T extends BlockData>(sharedRoot: YSharedRoot, sourceBlock: YBlock, type: BlockType, data: T) {
  const newBlock = createBlock(sharedRoot, {
    ty: type,
    data,
  });
  const newBlockId = newBlock.get(YjsEditorKey.block_id);

  if (!isEmbedBlockTypes(type)) {
    copyBlockText(sharedRoot, sourceBlock, newBlock);
  }

  const parent = getBlock(sourceBlock.get(YjsEditorKey.block_parent), sharedRoot);

  if (!parent) {
    return newBlockId;
  }

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

  extendNextSiblingsToToggleHeading(sharedRoot, newBlock);

  return newBlockId;
}

export function dataStringTOJson(data: string): object {
  try {
    return JSON.parse(data);
  } catch (e) {
    return {};
  }
}

export function moveNode(sharedRoot: YSharedRoot, sourceBlock: YBlock, targetParent: YBlock, targetIndex: number) {
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

export function deepCopyBlock(sharedRoot: YSharedRoot, sourceBlock: YBlock): string | null {
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

export function indentBlock(sharedRoot: YSharedRoot, block: YBlock) {

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

export function extendNextSiblingsToToggleHeading(sharedRoot: YSharedRoot, block: YBlock) {
  const type = block.get(YjsEditorKey.block_type);
  const data = dataStringTOJson(block.get(YjsEditorKey.block_data)) as ToggleListBlockData;

  if (type !== BlockType.ToggleListBlock || !data.level) return;

  const nextSiblings = getNextSiblings(sharedRoot, block);

  if (!nextSiblings || nextSiblings.length === 0) return;
  // find the next sibling with the same or higher level
  const index = nextSiblings.findIndex((id) => {
    const block = getBlock(id, sharedRoot);
    const blockData = dataStringTOJson(block.get(YjsEditorKey.block_data));

    if ('level' in blockData && (blockData as {
      level: number
    }).level <= ((data as unknown as ToggleListBlockData).level as number)) {
      return true;
    }

    return false;
  });

  const nodes = index > -1 ? nextSiblings.slice(0, index) : nextSiblings;

  // if not found, return. Otherwise, indent the block
  nodes.forEach((id) => {
    const block = getBlock(id, sharedRoot);

    indentBlock(sharedRoot, block);
  });
}

export function getPreviousSiblingBlock(sharedRoot: YSharedRoot, block: YBlock) {
  const parent = getBlock(block.get(YjsEditorKey.block_parent), sharedRoot);

  if (!parent) return;

  const parentChildren = getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot);
  const index = parentChildren.toArray().findIndex((id) => id === block.get(YjsEditorKey.block_id));

  if (index === 0) return null;
  return parentChildren.get(index - 1);
}

export function getNextSiblings(sharedRoot: YSharedRoot, block: YBlock) {
  const parent = getBlock(block.get(YjsEditorKey.block_parent), sharedRoot);

  if (!parent) return;

  const parentChildren = getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot);
  const index = parentChildren.toArray().findIndex((id) => id === block.get(YjsEditorKey.block_id));

  return parentChildren.toArray().slice(index + 1);
}

export function getSplitBlockOperations(sharedRoot: YSharedRoot, block: YBlock, offset: number): {
  select: boolean;
  operations: (() => void)[];
} {
  const operations: (() => void)[] = [];

  if (offset === 0) {
    operations.push(() => {
      const type = block.get(YjsEditorKey.block_type);
      const data = dataStringTOJson(block.get(YjsEditorKey.block_data));
      const isList = LIST_BLOCK_TYPES.includes(type);
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

export function deepCopyChildren(sharedRoot: YSharedRoot, sourceArray: Y.Array<string>, targetArray: Y.Array<string>, targetBlockId: string, index?: number) {

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

      if (sourceText && targetText) {
        targetText.applyDelta(sourceText.toDelta());
      }

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

export function mergeBlockChildren(sharedRoot: YSharedRoot, sourceBlock: YBlock, targetBlock: YBlock) {
  const targetType = targetBlock.get(YjsEditorKey.block_type);

  if (CONTAINER_BLOCK_TYPES.includes(targetType)) {
    transferChildren(sharedRoot, sourceBlock, targetBlock, 0);
  } else {
    liftChildren(sharedRoot, sourceBlock, targetBlock);
  }
}

export function liftBlock(sharedRoot: YSharedRoot, block: YBlock, offset?: number) {
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

  return moveNode(sharedRoot, block, grandParent, parentIndex + 1 + (offset || 0));
}

export function getBlocks(sharedRoot: YSharedRoot) {
  const document = getDocument(sharedRoot);

  return document.get(YjsEditorKey.blocks) as YBlocks;
}

export function appendEmptyParagraph(sharedRoot: YSharedRoot): string {
  const pageId = getPageId(sharedRoot);
  const page = getBlock(pageId, sharedRoot);
  const newBlock = createBlock(sharedRoot, {
    ty: BlockType.Paragraph,
    data: {},
  });

  updateBlockParent(sharedRoot, newBlock, page, 0);

  return newBlock.get(YjsEditorKey.block_id);
}

export function getParent(blockId: string, sharedRoot: YSharedRoot) {
  const block = getBlock(blockId, sharedRoot);

  if (!block) {
    return;
  }

  const parentId = block.get(YjsEditorKey.block_parent);

  return getBlock(parentId, sharedRoot);
}