import { CollabOrigin, CollabType, YDoc } from '@/application/collab.type';
import { getCollabStorageWithAPICall } from '@/application/services/js-services/storage';
import { FolderService } from '@/application/services/services.type';

export class JSFolderService implements FolderService {
  constructor() {
    //
  }

  async openWorkspace(workspaceId: string): Promise<YDoc> {
    const doc = await getCollabStorageWithAPICall(workspaceId, workspaceId, CollabType.Folder);
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
