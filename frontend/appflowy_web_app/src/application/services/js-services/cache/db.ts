import { YDoc } from '@/application/collab.type';
import { databasePrefix } from '@/application/constants';
import { IndexeddbPersistence } from 'y-indexeddb';
import * as Y from 'yjs';

const openedSet = new Set<string>();

/**
 * Open the collaboration database, and return a function to close it
 */
export async function openCollabDB(docName: string): Promise<YDoc> {
  const name = `${databasePrefix}_${docName}`;
  const doc = new Y.Doc();

  const provider = new IndexeddbPersistence(name, doc);

  let resolve: (value: unknown) => void;
  const promise = new Promise((resolveFn) => {
    resolve = resolveFn;
  });

  provider.on('synced', () => {
    if (!openedSet.has(name)) {
      openedSet.add(name);
    }

    resolve(true);
  });

  await promise;

  return doc as YDoc;
}

export function getCollabDBName(id: string, type: string, uuid?: string) {
  if (!uuid) {
    return `${type}_${id}`;
  }

  return `${uuid}_${type}_${id}`;
}
