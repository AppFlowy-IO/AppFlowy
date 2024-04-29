import { YDoc } from '@/application/document.type';
import { getAuthInfo } from '@/application/services/js-services/storage';
import * as Y from 'yjs';
import { IndexeddbPersistence } from 'y-indexeddb';
import { databasePrefix } from '@/application/constants';
import BaseDexie from 'dexie';
import { usersSchema, UsersTable } from './tables/users';

const version = 1;

type DexieTables = UsersTable;
export type Dexie<T = DexieTables> = BaseDexie & T;

let db: Dexie | undefined;

export function getDB() {
  const authInfo = getAuthInfo();

  if (!db && authInfo?.uuid) {
    return openDB(authInfo?.uuid);
  }

  return db;
}

export function openDB(uuid: string) {
  const dbName = `${databasePrefix}_${uuid}`;

  if (db && db.name === dbName) {
    return db;
  }

  db = new BaseDexie(dbName) as Dexie;
  const schema = Object.assign({}, usersSchema);

  db.version(version).stores(schema);
  return db;
}

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
