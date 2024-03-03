import {
  FolderEventListTrashItems,
  FolderEventPermanentlyDeleteAllTrashItem,
  FolderEventPermanentlyDeleteTrashItem,
  FolderEventRecoverAllTrashItems,
  FolderEventRestoreTrashItem,
  RepeatedTrashIdPB,
  TrashIdPB,
} from '@/services/backend/events/flowy-folder';

export const getTrash = async () => {
  const res = await FolderEventListTrashItems();

  if (res.ok) {
    return res.val.items;
  }

  return [];
};

export const putback = async (id: string) => {
  const payload = new TrashIdPB({
    id,
  });

  const res = await FolderEventRestoreTrashItem(payload);

  if (res.ok) {
    return res.val;
  }

  return Promise.reject(res.err);
};

export const deleteTrashItem = async (ids: string[]) => {
  const items = ids.map((id) => new TrashIdPB({ id }));
  const payload = new RepeatedTrashIdPB({
    items,
  });

  const res = await FolderEventPermanentlyDeleteTrashItem(payload);

  if (res.ok) {
    return res.val;
  }

  return Promise.reject(res.err);
};

export const deleteAll = async () => {
  const res = await FolderEventPermanentlyDeleteAllTrashItem();

  if (res.ok) {
    return res.val;
  }

  return Promise.reject(res.err);
};

export const restoreAll = async () => {
  const res = await FolderEventRecoverAllTrashItems();

  if (res.ok) {
    return res.val;
  }

  return Promise.reject(res.err);
};
