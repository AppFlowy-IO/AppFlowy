import { nanoid } from 'nanoid';
import { EditorData, EditorInlineNodeType, EditorNodeType, Mention } from '$app/application/document/document.types';
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

export function convertToSlateValue(data: EditorData): Element[] {
  const nodes: Element[] = [];
  const traverse = (id: string, level: number, isHidden?: boolean) => {
    const node = data.nodeMap[id];
    const delta = data.deltaMap[id];

    const slateNode: Element = {
      type: node.type,
      data: node.data,
      level,
      children: [],
      isHidden,
      blockId: id,
      parentId: node.parent || '',
      textId: node.externalId || '',
    };

    const inlineNodes: (Text | Element)[] = delta
      ? data.deltaMap[id].map((op) => {
          const matchInline = transformToInlineElement(op);

          if (matchInline) {
            return matchInline;
          }

          return {
            text: op.insert as string,
            ...op.attributes,
          };
        })
      : [];

    slateNode.children.push(...inlineNodes);

    nodes.push(slateNode);
    const children = data.childrenMap[id];

    if (children) {
      for (const childId of children) {
        let isHidden = false;

        if (node.type === EditorNodeType.ToggleListBlock) {
          const collapsed = (node.data as { collapsed: boolean })?.collapsed;

          if (collapsed) {
            isHidden = true;
          }
        }

        traverse(childId, level + 1, isHidden);
      }
    }

    return slateNode;
  };

  const rootId = data.rootId;

  traverse(rootId, 0);

  nodes.shift();

  return nodes;
}
