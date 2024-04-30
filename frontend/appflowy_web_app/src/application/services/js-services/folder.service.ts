import { CollabOrigin, CollabType, YDoc } from '@/application/collab.type';
import { getFolderStorage } from '@/application/services/js-services/storage/folder';
import { FolderService } from '@/application/services/services.type';
import { APIService } from 'src/application/services/js-services/wasm';
import { applyDocument } from 'src/application/ydoc/apply';

export class JSFolderService implements FolderService {
  constructor() {
    //
  }

  fetchFolder(workspaceId: string) {
    return APIService.getCollab(workspaceId, workspaceId, CollabType.Folder);
  }

  async openWorkspace(workspaceId: string): Promise<YDoc> {
    const { doc, localExist } = await getFolderStorage(workspaceId);
    const asyncApply = async () => {
      const res = await this.fetchFolder(workspaceId);

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
