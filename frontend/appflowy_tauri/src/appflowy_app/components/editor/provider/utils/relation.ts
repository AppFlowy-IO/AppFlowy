import * as Y from 'yjs';

export function getInsertTarget(root: Y.XmlText, path: (string | number)[]): Y.XmlText {
  const delta = root.toDelta();
  const index = path[0];

  const current = delta[index];

  if (current && current.insert instanceof Y.XmlText) {
    if (path.length === 1) {
      return current.insert;
    }

    return getInsertTarget(current.insert, path.slice(1));
  }

  return root;
}

export function getYTarget(doc: Y.Doc, path: (string | number)[]) {
  const sharedType = doc.get('sharedType', Y.XmlText) as Y.XmlText;

  return getInsertTarget(sharedType, path);
}
