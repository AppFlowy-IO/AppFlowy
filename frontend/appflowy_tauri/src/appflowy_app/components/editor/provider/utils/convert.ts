import { nanoid } from 'nanoid';
import { EditorData, EditorInlineNodeType, Mention } from '$app/application/document/document.types';
import { Element, Text } from 'slate';
import { Op } from 'quill-delta';

export function generateId() {
  return nanoid(10);
}

export function transformToInlineElement(op: Op): Element | null {
  const attributes = op.attributes;

  if (!attributes) return null;
  const isFormula = attributes.formula;

  if (isFormula) {
    return {
      type: EditorInlineNodeType.Formula,
      data: true,
      children: [
        {
          text: op.insert as string,
          ...attributes,
        },
      ],
    };
  }

  const matchMention = attributes.mention as Mention;

  if (matchMention) {
    return {
      type: EditorInlineNodeType.Mention,
      children: [
        {
          text: op.insert as string,
        },
      ],
      data: {
        ...matchMention,
      },
    };
  }

  return null;
}

export function getInlinesWithDelta(delta?: Op[]): (Text | Element)[] {
  return delta && delta.length > 0
    ? delta.map((op) => {
        const matchInline = transformToInlineElement(op);

        if (matchInline) {
          return matchInline;
        }

        return {
          text: op.insert as string,
          ...op.attributes,
        };
      })
    : [
        {
          text: '',
        },
      ];
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
