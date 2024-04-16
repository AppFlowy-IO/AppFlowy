import { YDoc } from '@/application/document.type';
import { getDocumentStorage } from '@/application/services/js-services/storage/document';
import { DocumentService } from '@/application/services/services.type';
import { APIService } from 'src/application/services/js-services/wasm';
import { CollabOrigin, CollabType } from '@/application/collab.type';
import { applyDocument } from 'src/application/services/js-services/apply';

export class JSDocumentService implements DocumentService {
  constructor() {
    //
  }

  fetchDocument(workspaceId: string, docId: string) {
    return APIService.getCollab(workspaceId, docId, CollabType.Document);
  }

  async openDocument(workspaceId: string, docId: string): Promise<YDoc> {
    const { doc, localExist } = await getDocumentStorage(docId);
    const asyncApply = async () => {
      const res = await this.fetchDocument(workspaceId, docId);

      applyDocument(doc, res.state);
    };

    // If the document exists locally, apply the state asynchronously,
    // otherwise, apply the state synchronously
    if (localExist) {
      void asyncApply();
    } else {
      await asyncApply();
    }

    const handleUpdate = (update: Uint8Array, origin: CollabOrigin) => {
      if (origin === CollabOrigin.Remote) {
        return;
      }

      // Send the update to the server
      console.log('update', update);
    };

    doc.on('update', handleUpdate);

    return doc;
  }
}
