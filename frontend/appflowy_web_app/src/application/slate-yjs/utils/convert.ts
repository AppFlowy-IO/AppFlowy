import { BlockJson } from '@/application/slate-yjs/types';
import { sortTableCells } from '@/application/slate-yjs/utils/table';
import {
  createBlock,
  getBlock,
  getText,
  updateBlockParent,
} from '@/application/slate-yjs/utils/yjsOperations';
import {
  BlockData,
  BlockType,
  YBlocks,
  YChildrenMap,
  YDoc,
  YjsEditorKey,
  YMeta,
  YSharedRoot,
  YTextMap,
} from '@/application/types';
import { TableCellNode } from '@/components/editor/editor.type';
import { Element, Text, Node } from 'slate';

export function yDataToSlateContent ({
  blocks,
  rootId,
  childrenMap,
  textMap,
}: {
  blocks: YBlocks;
  childrenMap: YChildrenMap;
  textMap: YTextMap;
  rootId: string;
}): Element | undefined {
  function traverse (id: string) {
    const block = blocks.get(id)?.toJSON() as BlockJson;

    if (!block) {
      console.error('Block not found', id);
      return;
    }

    const childrenId = block.children as string;

    const children = (childrenMap.get(childrenId)?.toJSON() ?? []).map(traverse).filter(Boolean) as (Element | Text)[];

    const slateNode = blockToSlateNode(block);

    if (slateNode.type === BlockType.TableBlock) {
      slateNode.children = sortTableCells(children as TableCellNode[]);
    } else if (slateNode.type === BlockType.TableCell) {
      slateNode.children = children.slice(0, 1);
    } else {
      slateNode.children = children;
    }

    if (slateNode.type === BlockType.Page) {
      return slateNode;
    }

    let textId = block.external_id as string;

    let delta;

    const yText = textId ? textMap.get(textId) : undefined;

    if (!yText) {
      if (children.length === 0) {
        children.push({
          text: '',
        });
      }

      // Compatible data
      // The old version of delta data is fully covered through the data field
      if (slateNode.data) {
        const data = slateNode.data as BlockData;

        if (YjsEditorKey.delta in data) {
          textId = block.id;
          delta = data.delta;
        } else {
          return slateNode;
        }
      }
    } else {
      delta = yText.toDelta();
    }

    try {
      const slateDelta = delta.flatMap(deltaInsertToSlateNode);

      if (slateDelta.length === 0) {
        slateDelta.push({
          text: '',
        });
      }

      const textNode: Element = {
        textId,
        type: YjsEditorKey.text,
        children: slateDelta,
      };

      children.unshift(textNode);
      return slateNode;
    } catch (e) {
      return;
    }
  }

  const root = blocks.get(rootId);

  if (!root) return;

  const result = traverse(rootId);

  if (!result) return;

  return result;
}

export function yDocToSlateContent (doc: YDoc): Element | undefined {
  const sharedRoot = doc.getMap(YjsEditorKey.data_section) as YSharedRoot;

  if (!sharedRoot || sharedRoot.size === 0) return;
  const document = sharedRoot.get(YjsEditorKey.document);
  const pageId = document.get(YjsEditorKey.page_id) as string;
  const blocks = document.get(YjsEditorKey.blocks) as YBlocks;

  const meta = document.get(YjsEditorKey.meta) as YMeta;
  const childrenMap = meta.get(YjsEditorKey.children_map) as YChildrenMap;
  const textMap = meta.get(YjsEditorKey.text_map) as YTextMap;

  return yDataToSlateContent({
    blocks,
    rootId: pageId,
    childrenMap,
    textMap,
  });
}

export function blockToSlateNode (block: BlockJson): Element {
  const data = block.data;
  let blockData;

  try {
    blockData = data ? JSON.parse(data) : {};
  } catch (e) {
    // do nothing
  }

  return {
    blockId: block.id,
    relationId: block.children,
    data: blockData,
    type: block.ty,
    children: [],
  };
}

export interface YDelta {
  insert: string;
  attributes?: object;
}

export function deltaInsertToSlateNode ({ attributes, insert }: YDelta): Element | Text | Element[] {

  if (attributes) {
    dealWithEmptyAttribute(attributes);
  }

  return {
    ...attributes,
    text: insert,
  };
}

// eslint-disable-next-line
function dealWithEmptyAttribute (attributes: Record<string, any>) {
  for (const key in attributes) {
    if (!attributes[key]) {
      delete attributes[key];
    }
  }
}

// Helper function to convert Slate text node to Delta insert
function slateNodeToDeltaInsert (node: Text): YDelta {
  const { text, ...attributes } = node;

  return {
    insert: text,
    attributes: Object.keys(attributes).length > 0 ? attributes : undefined,
  };
}

export function slateContentInsertToYData (
  parentBlockId: string,
  index: number,
  slateContent: Node[],
  doc: YDoc,
): string[] {
  // Get existing YData structures from the YDoc
  const sharedRoot = doc.getMap(YjsEditorKey.data_section) as YSharedRoot;

  function processNode (node: Element, parentId: string, index: number) {
    const parent = getBlock(parentId, sharedRoot);
    const block = createBlock(sharedRoot, {
      ty: node.type as BlockType,
      data: node.data || {},
    });

    const [textNode, ...children] = (node.children[0] as Element).textId ? [node.children[0] as Element, ...node.children.slice(1)] : [null, ...node.children];

    if (textNode) {
      const text = getText(block.get(YjsEditorKey.block_external_id), sharedRoot);
      const ops = (textNode.children as Text[]).map(slateNodeToDeltaInsert);

      text.applyDelta(ops);
    }

    updateBlockParent(sharedRoot, block, parent, index);

    children.forEach((child, i) => processNode(child as Element, block.get(YjsEditorKey.block_id), i));

    return block.get(YjsEditorKey.block_id);
  }

  // Process each top-level node in slateContent
  return slateContent.map((node, i) => processNode(node as Element, parentBlockId, index + i));
}