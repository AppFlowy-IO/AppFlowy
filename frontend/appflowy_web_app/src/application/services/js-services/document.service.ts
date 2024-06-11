import { CollabOrigin, CollabType, YDoc } from '@/application/collab.type';
import { getCollab } from '@/application/services/js-services/cache';
import { StrategyType } from '@/application/services/js-services/cache/types';
import { fetchCollab } from '@/application/services/js-services/fetch';
import { getCurrentWorkspace } from 'src/application/services/js-services/session';
import { DocumentService } from '@/application/services/services.type';

export class JSDocumentService implements DocumentService {
  private loaded: Set<string> = new Set();

  constructor() {
    //
  }

  async openDocument(docId: string): Promise<YDoc> {
    const workspace = await getCurrentWorkspace();

    if (!workspace) {
      throw new Error('Workspace database not found');
    }

    const isLoaded = this.loaded.has(docId);

    const doc = await getCollab(
      () => {
        return fetchCollab(workspace.id, docId, CollabType.Document);
      },
      {
        collabId: docId,
        collabType: CollabType.Document,
      },
      isLoaded ? StrategyType.CACHE_FIRST : StrategyType.CACHE_AND_NETWORK
    );

    if (!isLoaded) this.loaded.add(docId);
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
