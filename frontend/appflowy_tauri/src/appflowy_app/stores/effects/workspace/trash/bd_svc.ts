import {
  TrashIdPB,
  RepeatedTrashIdPB,
  FolderEventListTrashItems,
  FolderEventRestoreTrashItem,
  FolderEventPermanentlyDeleteTrashItem,
  FolderEventPermanentlyDeleteAllTrashItem,
  FolderEventRecoverAllTrashItems,
} from '@/services/backend/events/flowy-folder2';

export class TrashBackendService {
  constructor() {
    //
  }

  getTrash = async () => {
    return FolderEventListTrashItems();
  };

  putback = async (id: string) => {
    const payload = new TrashIdPB({
      id,
    });

    return FolderEventRestoreTrashItem(payload);
  };

  delete = async (ids: string[]) => {
    const items = ids.map((id) => new TrashIdPB({ id }));
    const payload = new RepeatedTrashIdPB({
      items,
    });

    return FolderEventPermanentlyDeleteTrashItem(payload);
  };

  deleteAll = async () => {
    return FolderEventPermanentlyDeleteAllTrashItem();
  };

  restoreAll = async () => {
    return FolderEventRecoverAllTrashItems();
  };
}
