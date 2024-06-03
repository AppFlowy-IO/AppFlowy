import { YDoc } from '@/application/collab.type';
import { DatabaseService } from '@/application/services/services.type';
import * as Y from 'yjs';

export class TauriDatabaseService implements DatabaseService {
  constructor() {
    //
  }

  async getWorkspaceDatabases(): Promise<{ views: string[]; database_id: string }[]> {
    return Promise.reject('Not implemented');
  }

  async closeDatabase(_databaseId: string) {
    return Promise.reject('Not implemented');
  }

  async openDatabase(_viewId: string): Promise<{
    databaseDoc: YDoc;
    rows: Y.Map<YDoc>;
  }> {
    return Promise.reject('Not implemented');
  }
}
