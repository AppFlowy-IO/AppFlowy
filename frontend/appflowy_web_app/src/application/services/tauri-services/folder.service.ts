import { YDoc } from '@/application/collab.type';
import { FolderService } from '@/application/services/services.type';

export class TauriFolderService implements FolderService {
  constructor() {
    //
  }

  async openWorkspace(_workspaceId: string): Promise<YDoc> {
    return Promise.reject('Not implemented');
  }
}
