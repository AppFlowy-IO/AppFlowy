import {
  InlineBlockType,
  YBlocks,
  YChildrenMap,
  YSharedRoot,
  YDoc,
  YjsEditorKey,
  YMeta,
  YTextMap,
  BlockData,
  BlockType,
} from '@/application/collab.type';
import { BlockJson } from '@/application/slate-yjs/utils/types';
import { Element, Text } from 'slate';

export function yDataToSlateContent({
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
  function traverse(id: string) {
    const block = blocks.get(id).toJSON() as BlockJson;
    const childrenId = block.children as string;

    const children = (childrenMap.get(childrenId)?.toJSON() ?? []).map(traverse) as (Element | Text)[];

    const slateNode = blockToSlateNode(block);

    slateNode.children = children;

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

export function yDocToSlateContent(doc: YDoc): Element | undefined {
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

export function blockToSlateNode(block: BlockJson): Element {
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
  attributes?: Record<string, string | number | undefined | boolean>;
}

export function deltaInsertToSlateNode({ attributes, insert }: YDelta): Element | Text | Element[] {
  const matchInlines = transformToInlineElement({
    insert,
    attributes,
  });

  if (matchInlines.length > 0) {
    return matchInlines;
  }

  if (attributes) {
    dealWithEmptyAttribute(attributes);
  }

  return {
    ...attributes,
    text: insert,
  };
}

function dealWithEmptyAttribute(attributes: Record<string, string | number | undefined | boolean>) {
  for (const key in attributes) {
    if (!attributes[key]) {
      delete attributes[key];
    }
  }
}

export function transformToInlineElement(op: YDelta): Element[] {
  const attributes = op.attributes;

  if (!attributes) return [];
  const { formula, mention, ...attrs } = attributes;

  if (formula) {
    const texts = op.insert.split('');

    return texts.map((text) => {
      return {
        type: InlineBlockType.Formula,
        data: formula,
        children: [
          {
            text,
            ...attrs,
          },
        ],
      };
    });
  }

  if (mention) {
    const texts = op.insert.split('');

    return texts.map((text) => {
      return {
        type: InlineBlockType.Mention,
        data: mention,
        children: [
          {
            text,
            ...attrs,
          },
        ],
      };
    });
  }

  return [];
}
