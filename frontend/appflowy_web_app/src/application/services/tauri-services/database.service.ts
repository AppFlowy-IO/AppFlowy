import { YDoc } from '@/application/collab.type';
import { DatabaseService } from '@/application/services/services.type';
import * as Y from 'yjs';

export class TauriDatabaseService implements DatabaseService {
  constructor() {
    //
  }

  async openDatabase(
    _workspaceId: string,
    _viewId: string
  ): Promise<{
    databaseDoc: YDoc;
    rows: Y.Map<YDoc>;
  }> {
    return Promise.reject('Not implemented');
  }

  async getDatabase(
    _workspaceId: string,
    _databaseId: string
  ): Promise<{
    databaseDoc: YDoc;
    rows: Y.Map<YDoc>;
  }> {
    return Promise.reject('Not implemented');
  }
}
