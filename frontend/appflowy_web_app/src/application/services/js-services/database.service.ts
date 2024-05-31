import { CollabType, YDatabase, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/collab.type';
import {
  batchCollabs,
  getCollabStorage,
  getCollabStorageWithAPICall,
  getCurrentWorkspace,
} from '@/application/services/js-services/storage';
import { DatabaseService } from '@/application/services/services.type';
import * as Y from 'yjs';

export class JSDatabaseService implements DatabaseService {
  private loadedDatabaseId: Set<string> = new Set();

  private cacheDatabaseRowDocMap: Map<string, Y.Doc> = new Map();

  constructor() {
    //
  }

  currentWorkspace() {
    return getCurrentWorkspace();
  }

  async getWorkspaceDatabases(): Promise<{ views: string[]; database_id: string }[]> {
    const workspace = await this.currentWorkspace();

    if (!workspace) {
      throw new Error('Workspace database not found');
    }

    const workspaceDatabase = await getCollabStorageWithAPICall(
      workspace.id,
      workspace.workspaceDatabaseId,
      CollabType.WorkspaceDatabase
    );

    return workspaceDatabase.getMap(YjsEditorKey.data_section).get(YjsEditorKey.workspace_database).toJSON() as {
      views: string[];
      database_id: string;
    }[];
  }

  async openDatabase(
    databaseId: string,
    rowIds?: string[]
  ): Promise<{
    databaseDoc: YDoc;
    rows: Y.Map<YDoc>;
  }> {
    const workspace = await this.currentWorkspace();

    if (!workspace) {
      throw new Error('Workspace database not found');
    }

    const workspaceId = workspace.id;
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
