import * as Y from 'yjs';
import { YDelta } from '$app/components/editor/provider/types/y_event';

export function findPreviousSibling(yXmlText: Y.XmlText) {
  let prev = yXmlText.prevSibling;

  if (!prev) return null;

  const level = yXmlText.getAttribute('level');

  while (prev) {
    const prevLevel = prev.getAttribute('level');

    if (prevLevel === level) return prev;
    if (prevLevel < level) return null;

    prev = prev.prevSibling;
  }

  return prev;
}

export function fillIdRelationMap(yXmlText: Y.XmlText, idRelationMap: Y.Map<string>) {
  const id = yXmlText.getAttribute('blockId');
  const parentId = yXmlText.getAttribute('parentId');

  if (id && parentId) {
    idRelationMap.set(id, parentId);
  }
}

export function convertToIdList(ops: YDelta) {
  return ops.map((op) => {
    if (op.insert instanceof Y.XmlText) {
      const id = op.insert.getAttribute('blockId');

      return {
        insert: {
          id,
        },
      };
    }

    return op;
  });
}
