import { CollabType, YDatabase, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/collab.type';
import { batchCollab, getCollab } from '@/application/services/js-services/cache';
import { StrategyType } from '@/application/services/js-services/cache/types';
import { batchFetchCollab, fetchCollab } from '@/application/services/js-services/fetch';
import { getCurrentWorkspace } from 'src/application/services/js-services/session';
import { DatabaseService } from '@/application/services/services.type';
import * as Y from 'yjs';

export class JSDatabaseService implements DatabaseService {
  private loadedDatabaseId: Set<string> = new Set();

  private loadedWorkspaceId: Set<string> = new Set();

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

    const isLoaded = this.loadedWorkspaceId.has(workspace.id);

    const workspaceDatabase = await getCollab(
      () => {
        return fetchCollab(workspace.id, workspace.workspaceDatabaseId, CollabType.WorkspaceDatabase);
      },
      {
        collabId: workspace.workspaceDatabaseId,
        collabType: CollabType.WorkspaceDatabase,
      },
      isLoaded ? StrategyType.CACHE_FIRST : StrategyType.CACHE_AND_NETWORK
    );

    if (!isLoaded) {
      this.loadedWorkspaceId.add(workspace.id);
    }

    return workspaceDatabase.getMap(YjsEditorKey.data_section).get(YjsEditorKey.workspace_database).toJSON() as {
      views: string[];
      database_id: string;
    }[];
  }

  async openDatabase(databaseId: string): Promise<{
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

    const databaseDoc = await getCollab(
      () => {
        return fetchCollab(workspaceId, databaseId, CollabType.Database);
      },
      {
        collabId: databaseId,
        collabType: CollabType.Database,
      },
      isLoaded ? StrategyType.CACHE_FIRST : StrategyType.CACHE_AND_NETWORK
    );

    if (!isLoaded) this.loadedDatabaseId.add(databaseId);

    const database = databaseDoc.getMap(YjsEditorKey.data_section)?.get(YjsEditorKey.database) as YDatabase;
    const viewId = database.get(YjsDatabaseKey.metas)?.get(YjsDatabaseKey.iid)?.toString();
    const rowOrders = database.get(YjsDatabaseKey.views)?.get(viewId)?.get(YjsDatabaseKey.row_orders);
    const rowOrdersIds = rowOrders.toJSON() as {
      id: string;
    }[];

    if (!rowOrdersIds) {
      throw new Error('Database rows not found');
    }

    const rowsParams = rowOrdersIds.map((item) => ({
      collabId: item.id,
      collabType: CollabType.DatabaseRow,
    }));

    void batchCollab(
      () => {
        return batchFetchCollab(workspaceId, rowsParams);
      },
      rowsParams,
      isLoaded ? StrategyType.CACHE_FIRST : StrategyType.CACHE_AND_NETWORK,
      (id: string, doc: YDoc) => {
        if (!rowsFolder.has(id)) {
          rowsFolder.set(id, doc);
        }
      }
    );

    // Update rows if there are new rows added after the database has been loaded
    rowOrders?.observe((event) => {
      if (event.changes.added.size > 0) {
        const rowIds = rowOrders.toJSON() as {
          id: string;
        }[];

        const params = rowIds.map((item) => ({
          collabId: item.id,
          collabType: CollabType.DatabaseRow,
        }));

        void batchCollab(
          () => {
            return batchFetchCollab(workspaceId, params);
          },
          params,
          StrategyType.CACHE_AND_NETWORK,
          (id: string, doc: YDoc) => {
            if (!rowsFolder.has(id)) {
              rowsFolder.set(id, doc);
            }
          }
        );
      }
    });

    return {
      databaseDoc,
      rows: rowsFolder,
    };
  }

  async closeDatabase(databaseId: string) {
    this.cacheDatabaseRowDocMap.delete(databaseId);
  }
}
