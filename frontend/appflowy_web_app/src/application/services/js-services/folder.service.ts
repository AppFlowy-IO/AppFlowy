import { CollabOrigin, CollabType, YDoc } from '@/application/collab.type';
import { getCollab } from '@/application/services/js-services/cache';
import { StrategyType } from '@/application/services/js-services/cache/types';
import { fetchCollab } from '@/application/services/js-services/fetch';
import { FolderService } from '@/application/services/services.type';

export class JSFolderService implements FolderService {
  private loaded: Set<string> = new Set();

  constructor() {
    //
  }

  async openWorkspace(workspaceId: string): Promise<YDoc> {
    const isLoaded = this.loaded.has(workspaceId);
    const doc = await getCollab(
      () => {
        return fetchCollab(workspaceId, workspaceId, CollabType.Folder);
      },
      {
        collabId: workspaceId,
        collabType: CollabType.Folder,
      },
      isLoaded ? StrategyType.CACHE_FIRST : StrategyType.CACHE_AND_NETWORK
    );

    if (!isLoaded) this.loaded.add(workspaceId);
    const handleUpdate = (update: Uint8Array, origin: CollabOrigin) => {
      if (origin === CollabOrigin.LocalSync) {
        // Send the update to the server
        console.log('update', update);
      }
    };

    doc.on('update', handleUpdate);

    return doc;
  }
}
