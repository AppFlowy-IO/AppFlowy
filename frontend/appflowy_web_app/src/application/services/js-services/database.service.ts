import { CollabOrigin, CollabType, YDatabase, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/collab.type';
import {
  batchCollabs,
  getCollabStorage,
  getCollabStorageWithAPICall,
  getUserWorkspace,
} from '@/application/services/js-services/storage';
import { DatabaseService } from '@/application/services/services.type';
import * as Y from 'yjs';

export class JSDatabaseService implements DatabaseService {
  private loadedDatabaseId: Set<string> = new Set();

  private cacheDatabaseRowDocMap: Map<string, Y.Doc> = new Map();

  constructor() {
    //
  }

  async getDatabase(
    workspaceId: string,
    databaseId: string,
    rowIds?: string[]
  ): Promise<{
    databaseDoc: YDoc;
    rows: Y.Map<YDoc>;
  }> {
    const isLoaded = this.loadedDatabaseId.has(databaseId);

    const rootRowsDoc =
      this.cacheDatabaseRowDocMap.get(databaseId) ??
      new Y.Doc({
        guid: databaseId,
      });

    if (!this.cacheDatabaseRowDocMap.has(databaseId)) {
      this.cacheDatabaseRowDocMap.set(databaseId, rootRowsDoc);
    }

    const rowsFolder: Y.Map<YDoc> = rootRowsDoc.getMap();

    let databaseDoc: YDoc | undefined = undefined;

    if (isLoaded) {
      databaseDoc = (await getCollabStorage(databaseId, CollabType.Database)).doc;
    } else {
      databaseDoc = await getCollabStorageWithAPICall(workspaceId, databaseId, CollabType.Database);
    }

    const database = databaseDoc.getMap(YjsEditorKey.data_section)?.get(YjsEditorKey.database) as YDatabase;
    const viewId = database.get(YjsDatabaseKey.metas)?.get(YjsDatabaseKey.iid)?.toString();
    const rowOrders = database.get(YjsDatabaseKey.views)?.get(viewId)?.get(YjsDatabaseKey.row_orders);
    const rowOrdersIds = rowOrders.toJSON() as {
      id: string;
    }[];

    if (!rowOrdersIds) {
      throw new Error('Database rows not found');
    }

    const ids = rowIds ? rowIds : rowOrdersIds.map((item) => item.id);

    if (isLoaded) {
      for (const id of ids) {
        const { doc } = await getCollabStorage(id, CollabType.DatabaseRow);

        if (!rowsFolder.has(id)) {
          rowsFolder.set(id, doc);
        }
      }
    } else {
      void this.loadDatabaseRows(workspaceId, ids, (id, row) => {
        if (!rowsFolder.has(id)) {
          rowsFolder.set(id, row);
        }
      });
    }

    this.loadedDatabaseId.add(databaseId);

    if (!rowIds) {
      // Update rows if new rows are added
      rowOrders?.observe((event) => {
        if (event.changes.added.size > 0) {
          const rowIds = rowOrders.toJSON() as {
            id: string;
          }[];

          console.log('Update rows', rowIds);
          void this.loadDatabaseRows(
            workspaceId,
            rowIds.map((item) => item.id),
            (rowId: string, rowDoc) => {
              if (!rowsFolder.has(rowId)) {
                rowsFolder.set(rowId, rowDoc);
              }
            }
          );
        }
      });
    }

    return {
      databaseDoc,
      rows: rowsFolder,
    };
  }

  async openDatabase(
    workspaceId: string,
    viewId: string,
    rowIds?: string[]
  ): Promise<{
    databaseDoc: YDoc;
    rows: Y.Map<YDoc>;
  }> {
    const userWorkspace = await getUserWorkspace();

    if (!userWorkspace) {
      throw new Error('User workspace not found');
    }

    const workspaceDatabaseId = userWorkspace.workspaces.find(
      (workspace) => workspace.id === workspaceId
    )?.workspaceDatabaseId;

    if (!workspaceDatabaseId) {
      throw new Error('Workspace database not found');
    }

    const workspaceDatabase = await getCollabStorageWithAPICall(
      workspaceId,
      workspaceDatabaseId,
      CollabType.WorkspaceDatabase
    );

    const databases = workspaceDatabase
      .getMap(YjsEditorKey.data_section)
      .get(YjsEditorKey.workspace_database)
      .toJSON() as {
      views: string[];
      database_id: string;
    }[];

    const databaseMeta = databases.find((item) => {
      return item.views.some((databaseViewId: string) => databaseViewId === viewId);
    });

    if (!databaseMeta) {
      throw new Error('Database not found');
    }

    const { databaseDoc, rows } = await this.getDatabase(workspaceId, databaseMeta.database_id, rowIds);

    const handleUpdate = (update: Uint8Array, origin: CollabOrigin) => {
      if (origin === CollabOrigin.LocalSync) {
        // Send the update to the server
        console.log('update', update);
      }
    };

    databaseDoc.on('update', handleUpdate);
    console.log('Database loaded', rows.toJSON());

    return {
      databaseDoc,
      rows,
    };
  }

  async loadDatabaseRows(workspaceId: string, rowIds: string[], rowCallback: (rowId: string, rowDoc: YDoc) => void) {
    try {
      await batchCollabs(
        workspaceId,
        rowIds.map((id) => ({
          object_id: id,
          collab_type: CollabType.DatabaseRow,
        })),
        rowCallback
      );
    } catch (e) {
      console.error(e);
    }
  }

  async closeDatabase(databaseId: string) {
    this.cacheDatabaseRowDocMap.delete(databaseId);
  }
}
