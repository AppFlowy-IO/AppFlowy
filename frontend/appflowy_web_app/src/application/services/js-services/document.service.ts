import { YDoc } from '@/application/document.type';
import { getDocumentStorage } from '@/application/services/js-services/storage/document';
import { DocumentService } from '@/application/services/services.type';
import { APIService } from 'src/application/services/js-services/wasm';
import { CollabOrigin, CollabType } from '@/application/collab.type';
import { getAuthInfo } from '@/application/services/js-services/storage/token';
import { applyDocument } from 'src/application/services/js-services/apply';

export class JSDocumentService implements DocumentService {
  constructor () {
    //
  }

  async openDocument (workspaceId: string, docId: string): Promise<YDoc> {
    const { uuid } = getAuthInfo() || {};

    if (!uuid) return Promise.reject(new Error('No user found'));

    const docName = `${uuid}_document_${docId}`;
    const { doc, localExist } = await getDocumentStorage(docName);
    const asyncApply = async () => {
      const res = await APIService.getCollab(workspaceId, docId, CollabType.Document);

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
