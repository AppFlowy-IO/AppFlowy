import { BlockPB } from '@/services/backend/models/flowy-document2';
import { nanoid } from 'nanoid';
import { Descendant, Element, Text } from 'slate';
import { BlockType, TextDelta } from '../interfaces/document';
import { Log } from './log';
export function generateId() {
  return nanoid(10);
}

export function deltaToSlateValue(delta: TextDelta[]) {
  const slateNode = {
    type: 'paragraph',
    children: [{ text: '' }],
  };
  const slateNodes = [slateNode];
  if (delta.length > 0) {
    slateNode.children = delta.map((d) => {
      return {
        ...d.attributes,
        text: d.insert,
      };
    });
  }
  return slateNodes;
}

export function getDeltaFromSlateNodes(slateNodes: Descendant[]) {
  const element = slateNodes[0] as Element;
  const children = element.children as Text[];
  return children.map((child) => {
    const { text, ...attributes } = child;
    return {
      insert: text,
      attributes,
    };
  });
}

export function blockPB2Node(block: BlockPB) {
  let data = {};
  try {
    data = JSON.parse(block.data);
  } catch {
    Log.error('[Document Open] json parse error', block.data);
  }
  const node = {
    id: block.id,
    type: block.ty as BlockType,
    parent: block.parent_id,
    children: block.children_id,
    data,
  };
  return node;
}
