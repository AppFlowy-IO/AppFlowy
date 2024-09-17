import { userSchema, UserTable } from '@/application/db/tables/users';
import { YDoc } from '@/application/types';
import { databasePrefix } from '@/application/constants';
import { IndexeddbPersistence } from 'y-indexeddb';
import * as Y from 'yjs';
import BaseDexie from 'dexie';
import { viewMetasSchema, ViewMetasTable } from '@/application/db/tables/view_metas';
import { rowSchema, rowTable } from '@/application/db/tables/rows';

type DexieTables = ViewMetasTable & UserTable & rowTable;

export type Dexie<T = DexieTables> = BaseDexie & T;

export const db = new BaseDexie(`${databasePrefix}_cache`) as Dexie;
const schema = Object.assign({}, { ...viewMetasSchema, ...userSchema, ...rowSchema });

db.version(1).stores(schema);

const openedSet = new Set<string>();

/**
 * Open the collaboration database, and return a function to close it
 */
export async function openCollabDB (docName: string): Promise<YDoc> {
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

export async function closeCollabDB (docName: string) {
  const name = `${databasePrefix}_${docName}`;

  if (openedSet.has(name)) {
    openedSet.delete(name);
  }

  const doc = new Y.Doc();

  const provider = new IndexeddbPersistence(name, doc);

  await provider.destroy();
}

export async function clearData () {
  const databases = await indexedDB.databases();
  
  const deleteDatabase = async (dbInfo: IDBDatabaseInfo): Promise<boolean> => {
    const dbName = dbInfo.name;

    if (!dbName) return false;

    return new Promise((resolve) => {
      const request = indexedDB.open(dbName);

      request.onsuccess = (event) => {
        const db = (event.target as IDBOpenDBRequest).result;

        db.close();

        const deleteRequest = indexedDB.deleteDatabase(dbName);

        deleteRequest.onsuccess = () => {
          console.log(`Database ${dbName} deleted successfully`);
          resolve(true);
        };

        deleteRequest.onerror = (event) => {
          console.error(`Error deleting database ${dbName}`, event);
          resolve(false);
        };

        deleteRequest.onblocked = () => {
          console.warn(`Delete operation blocked for database ${dbName}`);
          resolve(false);
        };
      };

      request.onerror = (event) => {
        console.error(`Error opening database ${dbName}`, event);
        resolve(false);
      };
    });
  };

  try {
    const results = await Promise.all(databases.map(deleteDatabase));

    return results.every(Boolean);
  } catch (error) {
    console.error('Error during database deletion process:', error);
    return false;
  }
}
