import { YDoc } from '@/application/collab.type';
import { databasePrefix } from '@/application/constants';
import { IndexeddbPersistence } from 'y-indexeddb';
import * as Y from 'yjs';
import BaseDexie from 'dexie';
import { viewMetasSchema, ViewMetasTable } from '@/application/db/tables/view_metas';

type DexieTables = ViewMetasTable;

export type Dexie<T = DexieTables> = BaseDexie & T;

export const db = new BaseDexie(`${databasePrefix}_cache`) as Dexie;
const schema = Object.assign({}, viewMetasSchema);

db.version(1).stores(schema);

const openedSet = new Set<string>();

/**
 * Open the collaboration database, and return a function to close it
 */
export async function openCollabDB(docName: string): Promise<YDoc> {
  const name = `${databasePrefix}_${docName}`;
  const doc = new Y.Doc({
    guid: docName,
  });

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

export async function closeCollabDB(docName: string) {
  const name = `${databasePrefix}_${docName}`;

  if (openedSet.has(name)) {
    openedSet.delete(name);
  }

  const doc = new Y.Doc();

  const provider = new IndexeddbPersistence(name, doc);

  await provider.destroy();
}

export async function clearData() {
  try {
    const databases = await indexedDB.databases();

    databases.forEach((dbInfo) => {
      const dbName = dbInfo.name as string;
      const request = indexedDB.open(dbName);

      request.onsuccess = function (event) {
        const db = (event.target as IDBOpenDBRequest).result;

        db.close();
        const deleteRequest = indexedDB.deleteDatabase(dbName);

        deleteRequest.onsuccess = function () {
          console.log(`Database ${dbName} deleted successfully`);
        };

        deleteRequest.onerror = function (event) {
          console.error(`Error deleting database ${dbName}`, event);
        };

        deleteRequest.onblocked = function () {
          console.warn(`Delete operation blocked for database ${dbName}`);
        };
      };

      request.onerror = function (event) {
        console.error(`Error opening database ${dbName}`, event);
      };
    });
  } catch (e) {
    console.error('Error listing databases:', e);
  }
}
