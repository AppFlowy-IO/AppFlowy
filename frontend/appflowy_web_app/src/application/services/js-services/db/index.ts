import { YDoc } from '@/application/collab.type';
import { databasePrefix } from '@/application/constants';
import { getAuthInfo } from '@/application/services/js-services/storage';
import { IndexeddbPersistence } from 'y-indexeddb';
import * as Y from 'yjs';

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
    resolve(true);
  });

  await promise;

  return doc as YDoc;
}

export async function deleteCollabDB(docName: string) {
  const name = `${databasePrefix}_${docName}`;
  const doc = new Y.Doc();
  const provider = new IndexeddbPersistence(name, doc);

  await provider.destroy();
}

export function getDBName(id: string, type: string) {
  const { uuid } = getAuthInfo() || {};

  if (!uuid) throw new Error('No user found');
  return `${uuid}_${type}_${id}`;
}
