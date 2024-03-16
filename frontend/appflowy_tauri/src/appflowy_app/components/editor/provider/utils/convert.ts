import { nanoid } from 'nanoid';
import { EditorData, EditorInlineNodeType, Mention } from '$app/application/document/document.types';
import { Element, Text } from 'slate';
import { Op } from 'quill-delta';

export function generateId() {
  return nanoid(10);
}

export function transformToInlineElement(op: Op): Element[] {
  const attributes = op.attributes;

  if (!attributes) return [];
  const { formula, mention, ...attrs } = attributes;

  if (formula) {
    const texts = (op.insert as string).split('');

    return texts.map((text) => {
      return {
        type: EditorInlineNodeType.Formula,
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
    const texts = (op.insert as string).split('');

    return texts.map((text) => {
      return {
        type: EditorInlineNodeType.Mention,
        children: [
          {
            text,
            ...attrs,
          },
        ],
        data: {
          ...(mention as Mention),
        },
      };
    });
  }

  return [];
}

export function getInlinesWithDelta(delta?: Op[]): (Text | Element)[] {
  const newDelta: (Text | Element)[] = [];

  if (!delta || !delta.length)
    return [
      {
        text: '',
      },
    ];

  delta.forEach((op) => {
    const matchInlines = transformToInlineElement(op);

    if (matchInlines.length > 0) {
      newDelta.push(...matchInlines);
      return;
    }

    if (op.attributes) {
      if ('font_color' in op.attributes && op.attributes['font_color'] === '') {
        delete op.attributes['font_color'];
      }

      if ('bg_color' in op.attributes && op.attributes['bg_color'] === '') {
        delete op.attributes['bg_color'];
      }

      if ('code' in op.attributes && !op.attributes['code']) {
        delete op.attributes['code'];
      }
    }

    newDelta.push({
      text: op.insert as string,
      ...op.attributes,
    });
  });

  return newDelta;
}

export function convertToSlateValue(data: EditorData, includeRoot: boolean): Element[] {
  const traverse = (id: string, isRoot = false) => {
    const node = data.nodeMap[id];
    const delta = data.deltaMap[id];

    const slateNode: Element = {
      type: node.type,
      data: node.data,
      children: [],
      blockId: id,
    };

    const textNode: Element | null =
      !isRoot && node.externalId
        ? {
            type: 'text',
            children: [],
            textId: node.externalId,
          }
        : null;

    const inlineNodes = getInlinesWithDelta(delta);

    textNode?.children.push(...inlineNodes);

    const children = data.childrenMap[id];

    slateNode.children = children.map((childId) => traverse(childId));
    if (textNode) {
      slateNode.children.unshift(textNode);
    }

    return slateNode;
  };

  const rootId = data.rootId;

  const root = traverse(rootId, true);

  const nodes = root.children as Element[];

  if (includeRoot) {
    nodes.unshift({
      ...root,
      children: [
        {
          type: 'text',
          children: [
            {
              text: '',
            },
          ],
        },
      ],
    });
  }

  return nodes;
}
