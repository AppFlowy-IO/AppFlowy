import { nanoid } from 'nanoid';
import { Descendant, Element, Text } from 'slate';
import { TextDelta } from '../interfaces/document';

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
