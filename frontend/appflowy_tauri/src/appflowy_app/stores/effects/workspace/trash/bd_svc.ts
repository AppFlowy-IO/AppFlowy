import {
  FolderEventReadTrash,
  FolderEventPutbackTrash,
  FolderEventDeleteAllTrash,
  FolderEventRestoreAllTrash,
  FolderEventDeleteTrash,
  TrashIdPB,
  RepeatedTrashIdPB,
} from '@/services/backend/events/flowy-folder2';

export class TrashBackendService {
  constructor() {
    //
  }

  getTrash = async () => {
    return FolderEventReadTrash();
  };

  putback = async (id: string) => {
    const payload = new TrashIdPB({
      id,
    });

    return FolderEventPutbackTrash(payload);
  };

  delete = async (ids: string[]) => {
    const items = ids.map((id) => new TrashIdPB({ id }));
    const payload = new RepeatedTrashIdPB({
      items,
    });

    return FolderEventDeleteTrash(payload);
  };

  deleteAll = async () => {
    return FolderEventDeleteAllTrash();
  };

  restoreAll = async () => {
    return FolderEventRestoreAllTrash();
  };
}
