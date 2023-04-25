import { nanoid } from 'nanoid';
import { Descendant, Element, Text } from 'slate';
import { TextDelta, BlockType, NestedBlock } from '../interfaces/document';
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

export function blockChangeValue2Node(value: {
  id: string;
  ty: string;
  parent: string;
  children: string;
  data: string;
}): NestedBlock {
  const block = {
    id: value.id,
    type: value.ty as BlockType,
    parent: value.parent,
    children: value.children,
    data: {},
  };
  if ('data' in value && typeof value.data === 'string') {
    try {
      Object.assign(block, {
        data: JSON.parse(value.data),
      });
    } catch {
      Log.error('valueJson data parse error', block.data);
    }
  }

  return block;
}
