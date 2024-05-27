import { CollabOrigin, CollabType, YDoc } from '@/application/collab.type';
import { getCollabStorageWithAPICall } from '@/application/services/js-services/storage';
import { DocumentService } from '@/application/services/services.type';

export class JSDocumentService implements DocumentService {
  constructor() {
    //
  }

  async openDocument(workspaceId: string, docId: string): Promise<YDoc> {
    const doc = await getCollabStorageWithAPICall(workspaceId, docId, CollabType.Document);

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
