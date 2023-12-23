import * as Y from 'yjs';
import { YDelta } from '$app/components/editor/provider/types/y_event';

export function getStructureFromDelta(rootId: string, delta: YDelta) {
  const map = new Map();

  const traverse = (
    delta: YDelta
  ): {
    id: string;
    type: string;
  }[] => {
    const children: {
      id: string;
      type: string;
    }[] = [];

    delta.forEach((op) => {
      if (op.insert && op.insert instanceof Y.XmlText) {
        const blockId = op.insert.getAttribute('blockId');
        const textId = op.insert.getAttribute('textId');

        if (blockId) {
          map.set(blockId, traverse(op.insert.toDelta()));
          children.push({ type: 'block', id: blockId });
        }

        if (textId) {
          children.push({
            type: 'text',
            id: textId,
          });
        }
      }
    });

    return children;
  };

  map.set(rootId, traverse(delta));

  return map;
}

export function getYTarget(doc: Y.Doc, path: (string | number)[]) {
  const sharedType = doc.get('sharedType', Y.XmlText) as Y.XmlText;

  const getTarget = (node: Y.XmlText, path: (string | number)[]): Y.XmlText => {
    if (path.length === 0) return node;
    const delta = node.toDelta();
    const index = path[0];

    const current = delta[index];

    if (current.insert instanceof Y.XmlText) {
      if (path.length === 1) {
        return current.insert;
      }

      return getTarget(current.insert, path.slice(1));
    }

    return node;
  };

  return getTarget(sharedType, path);
}
